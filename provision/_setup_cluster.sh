#!/usr/bin/env bash

# Spark Standalone mode

source ~/provision/_init.sh

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

sudo chmod 777 $SW_DIR

cd $SW_DIR

wget -nv http://downloads.lightbend.com/scala/2.10.6/scala-2.10.6.tgz
tar xf scala-2.10.6.tgz
scala -version
rm scala-2.10.6.tgz

wget -nv http://d3kbcqa49mib13.cloudfront.net/spark-1.6.2-bin-hadoop2.6.tgz
tar xf spark-1.6.2-bin-hadoop2.6.tgz
rm spark-1.6.2-bin-hadoop2.6.tgz


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

. stop-all.sh

