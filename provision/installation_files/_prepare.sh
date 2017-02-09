
METAPIPE_DIR=/export/share
SPARK_HOME=/export/share/spark-1.6.2-bin-hadoop2.6

sudo chmod 777 $METAPIPE_DIR
cd $METAPIPE_DIR

DISK_NAME="$1"

if [ "$2" != "skip-unpack" ]; then
    sudo tar xvf metapipe-dependencies.tar.gz
    sudo mv package/dist .
    sudo mv dist metapipe
fi
#sudo cp /media/$DISK_NAME/sw-packed/*.sh $METAPIPE_DIR
#sudo cp /media/$DISK_NAME/sw-packed/conf.json $METAPIPE_DIR
#sudo cp /media/$DISK_NAME/sw-packed/workflow-assembly-0.1-SNAPSHOT.jar $METAPIPE_DIR

sudo mkdir $METAPIPE_DIR/.metapipe
sudo mkdir $METAPIPE_DIR/metapipe-tmp
#sudo rm conf.json
echo "{
  \"metapipeHome\": \"$METAPIPE_DIR/metapipe\",
  \"metapipeTemp\": \"$METAPIPE_DIR/metapipe-tmp\"
}" > conf.json
cat conf.json
sudo cp conf.json $METAPIPE_DIR/.metapipe
sudo cp conf.json $METAPIPE_DIR/metapipe
sudo chmod 777 -R $METAPIPE_DIR
sudo rm /home/cloud-user/.metapipe
sudo ln -s $METAPIPE_DIR/.metapipe /home/cloud-user/

# Temporary solution for missing Perl module Data/Dumper.pm
sudo yum -y install perl-CPAN
for name in "${WORKER_HOSTS[@]}"; do
    echo "$name"
    ssh -n -o StrictHostKeyChecking=no cloud-user@$name "sudo yum -y install perl-CPAN"
done

>| $METAPIPE_DIR/metapipe-tmp/assembly_running
for name in "${WORKER_HOSTS[@]}"; do
    echo "0" >> $METAPIPE_DIR/metapipe-tmp/assembly_running
done
cat $METAPIPE_DIR/metapipe-tmp/assembly_running

echo "METAPIPE_DIR=$METAPIPE_DIR" >> $SPARK_HOME/conf/spark-env.sh

# sudo kill $(ps aux | grep "spark" | awk '{print $2}')
