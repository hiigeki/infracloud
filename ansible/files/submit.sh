#!/bin/sh
hdfs namenode -format
start-dfs.sh
hdfs dfs -mkdir /input
hdfs dfs -mkdir /ouput
hdfs dfs -put /home/ubuntu/spark/tp2/tpSpark/filesample.txt /input
javac -cp "lib/*" /home/ubuntu/spark/tp2/tpSpark/src/pack/WordCount.java -d /home/ubuntu/spark/tp2/tpSpark/bin
jar cf wc.jar -C /home/ubuntu/spark/tp2/tpSpark/bin pack
start-master.sh
start-slaves.sh
spark-submit --class pack.WordCount --master spark://vm0.example.com:7077 /home/ubuntu/spark/tp2/tpSpark/wc.jar
hdfs dfs -get /ouput/resultwc /home/ubuntu/spark
stop-master.sh
stop-slaves.sh
stop-dfs.sh
