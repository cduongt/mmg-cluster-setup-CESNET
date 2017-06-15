source ~/provision/_init.sh

chmod +x ~/provision/installation_files/_run.sh

cd $METAPIPE_DIR

cp /cvmfs/metapipe.cesnet.cz/workflow-assembly-0.1-SNAPSHOT.jar $METAPIPE_DIR

mkdir $METAPIPE_DIR/.metapipe
mkdir $METAPIPE_DIR/metapipe-tmp

echo "{
  \"metapipeHome\": \"$METAPIPE_DIR/metapipe\",
  \"metapipeTemp\": \"$METAPIPE_DIR/metapipe-tmp\"
}" > conf.json
cat conf.json
 cp conf.json $METAPIPE_DIR/.metapipe
#sudo cp conf.json $METAPIPE_DIR/metapipe
#sudo chmod 777 -R $METAPIPE_DIR
rm /home/cloud-user/.metapipe
ln -s $METAPIPE_DIR/.metapipe /home/cloud-user/

>| $METAPIPE_DIR/metapipe-tmp/assembly_running
for name in "${WORKER_HOSTS[@]}"; do
    echo "0" >> $METAPIPE_DIR/metapipe-tmp/assembly_running
done
cat $METAPIPE_DIR/metapipe-tmp/assembly_running

echo "METAPIPE_DIR=$METAPIPE_DIR" >> $SPARK_HOME/conf/spark-env.sh
