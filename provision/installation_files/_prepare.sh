source ~/provision/_init.sh

chmod +x ~/provision/installation_files/_run.sh

sudo chmod 777 $METAPIPE_DIR
cd $METAPIPE_DIR

DISK_NAME="$1"

if [ "$2" != "skip-unpack" ]; then
    sudo tar xvf metapipe-dependencies.tar.gz
    sudo mv package/dist .
    sudo mv dist metapipe
    sudo rm metapipe-dependencies.tar.gz
fi

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

>| $METAPIPE_DIR/metapipe-tmp/assembly_running
for name in "${WORKER_HOSTS[@]}"; do
    echo "0" >> $METAPIPE_DIR/metapipe-tmp/assembly_running
done
cat $METAPIPE_DIR/metapipe-tmp/assembly_running

echo "METAPIPE_DIR=$METAPIPE_DIR" >> $SPARK_HOME/conf/spark-env.sh
