// variables that can be overriden
# variable "hostname" { default = ["vm1","vm2","vm3","vm4"] }
variable "hostname" { default = "vm" }
variable "ip" { default = ["192.168.122.100","192.168.122.101","192.168.122.102","192.168.122.103"]}
variable "domain" { default = "example.com" }
variable "ip_type" { default = "dhcp" } # dhcp is other valid type
variable "memoryMB" { default = 1024*1 }
variable "cpu" { default = 1 }
variable "number_instances" { default = 4}

// fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "os_image" {
  # for_each = toset(var.hostname)
  count = var.number_instances
  name = "${var.hostname}${count.index}-os_image"
  pool = "default"
  source = "jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

// Use CloudInit ISO to add ssh-key to the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  # for_each = toset(var.hostname)
  count = var.number_instances
  name = "${var.hostname}${count.index}-commoninit.iso"
  pool = "default"
  user_data      = data.template_cloudinit_config.config[count.index].rendered
  network_config = data.template_file.network_config[count.index].rendered
}

data "template_file" "user_data" {
  # for_each = toset(var.hostname)
  count = var.number_instances
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    hostname = "${var.hostname}${count.index}"
    fqdn = "${var.hostname}${count.index}.${var.domain}"
    public_key = file("~/.ssh/id_ed25519.pub")
  }
}

data "template_cloudinit_config" "config" {
  # for_each = toset(var.hostname)
  count = var.number_instances
  gzip = false
  base64_encode = false
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = data.template_file.user_data[count.index].rendered
  }
}

data "template_file" "network_config" {
  count = var.number_instances
  template = file("${path.module}/network_config_${var.ip_type}.cfg")
  vars = {
    ip = var.ip[count.index]
  }
}


resource "libvirt_network" "examplenet" {
  name = "examplenet"

  addresses = ["192.168.122.0/24"]

  domain = var.domain

  mode = "nat"

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
    local_only = false
    hosts {
      hostname = "vm0"
      ip = "192.168.122.100"
    }
    hosts {
      hostname = "vm1"
      ip = "192.168.122.101"
    }
    hosts {
      hostname = "vm2"
      ip = "192.168.122.102"
    }
    hosts {
      hostname = "vm3"
      ip = "192.168.122.103"
    }
  }
}

// Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  # domain name in libvirt, not hostname
  # for_each = toset(var.hostname)
  count = var.number_instances
  name = "${var.hostname}${count.index}"
  memory = var.memoryMB
  vcpu = var.cpu


  disk {
    volume_id = libvirt_volume.os_image[count.index].id
  }
  network_interface {
    network_id = libvirt_network.examplenet.id
    addresses = [var.ip[count.index]]
    hostname = "${var.hostname}${count.index}"
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  # console {
  #   type        = "pty"
  #   target_port = "0"
  #   target_type = "serial"
  # }

  # graphics {
  #   type = "spice"
  #   listen_type = "address"
  #   autoport = "true"
  # }
}

output "ips" {
  value = [ for domain in libvirt_domain.domain-ubuntu : length(domain.network_interface[0].addresses)>0 ? domain.network_interface[0].addresses[0] : "null" ]
}