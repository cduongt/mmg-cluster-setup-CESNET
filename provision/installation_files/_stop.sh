
source ~/provision/_init.sh

stop-all.sh

sleep 1

sudo kill -9 $(jps | grep "Master" | cut -d " " -f 1) 2> /dev/null
sudo kill -9 `jps | grep "SparkSubmit" | cut -d " " -f 1` 2> /dev/null
sudo kill -9 $(ps aux | grep 'spark' | awk '{print $2}')
for name in "${WORKER_HOSTS[@]}"; do
    echo "$name"
    ssh -n -o StrictHostKeyChecking=no cloud-user@$name "
    sudo kill -9 `jps | grep "Master" | cut -d " " -f 1` 2> /dev/null
    sudo kill -9 `jps | grep "SparkSubmit" | cut -d " " -f 1` 2> /dev/null
    sudo kill -9 $(ps aux | grep 'spark' | awk '{print $2}')
    "
done
