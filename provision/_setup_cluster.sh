#!/usr/bin/env bash

# Spark Standalone mode

SW_DIR=/export/share
CLUSTER_NAME="stoor"

CORES_MASTER=4
RAM_MASTER=4
CORES_PER_SLAVE=1
RAM_PER_SLAVE=1
EXECUTORS_PER_SLAVE=$(($CORES_PER_SLAVE / 1))

CORES_PER_EXECUTOR=8
RAM_PER_EXECUTOR=$(($RAM_PER_SLAVE / $EXECUTORS_PER_SLAVE))

unset WORKER_HOSTS
declare -a WORKER_HOSTS
while read -r x; do
    temp_str=$(printf "$x" | head -n1 | awk '{print $1;}');
    if [[ $temp_str == *"$CLUSTER_NAME"* ]]; then
      WORKER_HOSTS[${#WORKER_HOSTS[*]}]=$temp_str
    fi
done < <(/usr/sbin/arp -a)
echo "Found connected slaves:"
printf '%s\n' "${WORKER_HOSTS[@]}"

NUM_SLAVES=${#WORKER_HOSTS[*]}


export PATH=$PATH:$SW_DIR/scala-2.10.6/bin
export SPARK_HOME=$SW_DIR/spark-1.6.2-bin-hadoop2.6
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin


if [ "$1" == "test" ]; then
    SCRIPT="$2"
    . start-all.sh
    SPARK_CONF="\
        --driver-memory $(($RAM_MASTER))G \
        --executor-memory $(($RAM_PER_EXECUTOR))G \
        --conf spark.task.cpus=$CORES_PER_EXECUTOR \
        --conf spark.cores.max=$(($CORES_PER_SLAVE * $NUM_SLAVES))"
    # Spark Standalone, client mode
    $SPARK_HOME/bin/spark-submit \
        --master spark://$(hostname):7077 \
        $SPARK_CONF \
        ~/$SCRIPT
    . stop-all.sh
    exit 1
fi

cd $SW_DIR

sudo yum install wget -y
sudo wget -nv http://downloads.lightbend.com/scala/2.10.6/scala-2.10.6.tgz
sudo tar xf scala-2.10.6.tgz
scala -version
sudo rm scala-2.10.6.tgz

sudo wget -nv http://d3kbcqa49mib13.cloudfront.net/spark-1.6.2-bin-hadoop2.6.tgz
sudo tar xf spark-1.6.2-bin-hadoop2.6.tgz
sudo rm spark-1.6.2-bin-hadoop2.6.tgz

sudo chmod 777 -R $SW_DIR/*

>| $SPARK_HOME/conf/slaves
for name in "${WORKER_HOSTS[@]}"; do
    echo "$name" >> $SPARK_HOME/conf/slaves
done
cat $SPARK_HOME/conf/slaves

>| $SPARK_HOME/conf/spark-env.sh
>| $SPARK_HOME/conf/spark-defaults.conf
#echo "spark.memory.fraction" "0.9" >> $SPARK_HOME/conf/spark-defaults.conf
echo "spark.deploy.defaultCores" "$(($CORES_PER_SLAVE * $NUM_SLAVES))" >> $SPARK_HOME/conf/spark-defaults.conf
echo "export SPARK_WORKER_INSTANCES=$EXECUTORS_PER_SLAVE" >> $SPARK_HOME/conf/spark-env.sh
echo "export SPARK_WORKER_MEMORY=$(($RAM_PER_EXECUTOR))g" >> $SPARK_HOME/conf/spark-env.sh

. start-all.sh
sudo chmod 777 -R $SW_DIR/*
. stop-all.sh

