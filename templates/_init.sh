
SW_DIR=/export/share

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


