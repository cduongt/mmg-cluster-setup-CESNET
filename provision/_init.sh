
SW_DIR=/export/share

CORES_MASTER=4
RAM_MASTER=4
CORES_PER_SLAVE=4
RAM_PER_SLAVE=4

CORES_PER_EXECUTOR=4
EXECUTORS_PER_SLAVE=$(($CORES_PER_SLAVE / $CORES_PER_EXECUTOR))
RAM_PER_EXECUTOR=$(($RAM_PER_SLAVE / $EXECUTORS_PER_SLAVE))

unset WORKER_HOSTS
declare -a WORKER_HOSTS
while read LINE
do
    WORKER_HOSTS[${#WORKER_HOSTS[*]}]=$LINE
done < /home/cloud-user/provision/slaves
echo "Found connected slaves:"
printf '%s\n' "${WORKER_HOSTS[@]}"

NUM_SLAVES=${#WORKER_HOSTS[*]}

export PATH=$PATH:$SW_DIR/scala-2.10.6/bin
export SPARK_HOME=$SW_DIR/spark-1.6.2-bin-hadoop2.6
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
export METAPIPE_DIR=$SW_DIR


