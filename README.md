
# Rapport de projet : Automatisation d'une infrastructure Big Data

## Introduction
L'objectif de ce projet est d'automatiser le déploiement d'un cluster Hadoop/Spark pour traiter efficacement des volumes importants de données. Le déploiement est réalisé sur une infrastructure virtualisée basée sur KVM. Cette approche utilise deux outils principaux: 
- **Terraform**, pour créer et configurer l'infrastructure, notamment les machines virtuelles et le réseau.
- **Ansible**, pour gérer la configuration des services et orchestrer leur installation sur les machines.

Le système inclut HDFS pour le stockage distribué, et l'application `WordCount` pour valider la fonctionnalité du cluster. Cette validation garantit que le cluster peut traiter un fichier texte et générer des résultats dans HDFS. Le projet met en avant les avantages de l'Infrastructure as Code (IaC) pour automatiser des tâches complexes, tout en permettant une extensibilité future vers des configurations plus avancées.

## Structure et rôles des fichiers

### Répertoire Terraform
Le répertoire `terraform/` contient les fichiers nécessaires à la création des ressources de l'infrastructure virtuelle :
- `main.tf`: Fichier principal définissant la configuration des machines virtuelles, y compris la quantité de mémoire, le nombre de cœurs CPU et les paramètres réseau.
- `cloud_init.cfg`: Permet de configurer chaque VM au moment de sa création (installation d'outils de base, ajout des utilisateurs).
- `network_config_dhcp.cfg` et `network_config_static.cfg`: Permettent de choisir entre une configuration réseau dynamique (DHCP) ou statique.
- `sshkeys/`: Stocke les clés SSH pour permettre une connexion sécurisée sans mot de passe entre les machines.
- `rmsshkeys.sh`: Script pour supprimer les clés SSH obsolètes et éviter les conflits lors des reconstructions de l'infrastructure.

### Répertoire Ansible
Le répertoire `ansible/` contient les fichiers pour automatiser l'installation et la configuration des services :
- `ansible.cfg`: Fichier de configuration spécifiant le fichier d'inventaire et les paramètres de connexion SSH.
- `inventory.ini`: Définit les machines cibles (nœud maître et esclaves) ainsi que leurs adresses IP.
- `spark.yml`: Playbook principal pour installer Spark, en configurant à la fois le Spark Master et les Spark Workers.
- `ssh.yml`: Playbook permettant de configurer les connexions SSH partagées entre les machines.
- `submit.yml`: Automatisation de la soumission des tâches Spark, comme l'application `WordCount`.
- `files/`: Contient les fichiers de configuration et les applications nécessaires :
    - `core-site.xml`: Configure les paramètres HDFS de base, y compris le NameNode.
    - `hdfs-site.xml`: Définit les paramètres de réplication et de stockage pour HDFS.
    - `spark-env.sh`: Définit les variables d'environnement pour le bon fonctionnement de Spark.
    - `tpSpark/`: Dossier contenant l'application WordCount, avec :
        - `WordCount.java`: Le code source de l'application.
        - `wc.jar`: Fichier exécutable de l'application après compilation.
        - `lib/`: Bibliothèques nécessaires pour exécuter l'application dans le cluster Spark.

## Déroulement du projet

### Phase 1 : Infrastructure avec Terraform
La première étape consiste à définir et à appliquer la configuration de l'infrastructure avec Terraform (`terraform apply`). Cela permet de créer une architecture composée de :
- 4 machines virtuelles sous Ubuntu, incluant un nœud maître et trois nœuds esclaves.
- Un réseau isolé offrant une connectivité sécurisée via SSH entre les nœuds.
- Des disques persistants attachés à chaque VM, permettant de conserver les données en cas de redémarrage.
- Une configuration réseau personnalisée (DHCP ou IP statiques).

Terraform permet une gestion centralisée et reproductible de l'infrastructure. Par exemple, si une modification est apportée à la configuration (comme le nombre de nœuds ou la quantité de ressources), il suffit de réappliquer les changements pour ajuster l'environnement.

### Phase 2 : Déploiement Ansible
Une fois les machines prêtes, les playbooks Ansible prennent le relais pour configurer et installer les services nécessaires :
- Configuration d'un accès SSH entre les machines pour permettre une communication fluide sans mot de passe.
- Installation des dépendances, comme Java 8, Scala et les bibliothèques nécessaires pour Spark et Hadoop.
- Déploiement de Hadoop :
    - Le NameNode est configuré sur le nœud maître pour gérer le système de fichiers HDFS.
    - Les DataNodes sont déployés sur les nœuds esclaves, permettant un stockage distribué.
- Installation et configuration de Spark :
    - Le Spark Master est déployé sur le nœud principal, avec une interface permettant de soumettre et suivre les tâches.
    - Les Spark Workers sont déployés sur les nœuds esclaves pour exécuter les calculs.

### Phase 3 : Validation opérationnelle
La validation consiste à s'assurer que le cluster fonctionne comme prévu :
- L'application WordCount (`wc.jar`) est copiée sur le cluster.
- Un fichier texte est soumis en entrée via le système HDFS.
- Le job est lancé avec Spark, et les résultats sont enregistrés dans HDFS. La sortie est vérifiée pour confirmer le traitement correct du fichier.

### Phase 4 : Extension multi-physique (non réalisée)
Cette phase, initialement prévue, vise à étendre l'infrastructure au-delà de l'hôte local KVM. Elle inclurait :
- La répartition des nœuds sur plusieurs serveurs physiques.
- La configuration d'un réseau VxLAN.
- Une gestion distribuée des données et des tâches, adaptée à des environnements multi-serveurs.

## Conclusion
Ce projet nous a permis de de manipuler et comprendre des outils d'Infrastructure as Code comme Terraform et Ansible pour automatiser le déploiement de systèmes Big Data. Terraform a permis de créer une infrastructure reproductible et modifiable, tandis qu'Ansible a simplifié la configuration et l'installation des services Hadoop et Spark. Ce projet illustre le potentiel de l'IaC pour construire des infrastructures adaptées aux besoins de la technologie Big Data.

