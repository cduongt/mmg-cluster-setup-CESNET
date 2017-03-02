
SW_DIR=/export/share
CLUSTER_NAME="stoor"

CORES_MASTER=4
RAM_MASTER=4
CORES_PER_SLAVE=4
RAM_PER_SLAVE=4
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
export METAPIPE_DIR=$SW_DIR


