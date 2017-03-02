source ~/provision/_init.sh

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

# Temporary solution for missing Perl module Data/Dumper.pm and Digest::MD5
sudo yum -y install perl-CPAN
sudo yum -y install perl-Digest-MD5
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
cpanm Digest::MD5
for name in "${WORKER_HOSTS[@]}"; do
    echo "$name"
    ssh -t -o StrictHostKeyChecking=no cloud-user@$name '
    sudo yum -y install perl-CPAN
    sudo yum -y install perl-Digest-MD5
    curl -L https://cpanmin.us | perl - --sudo App::cpanminus
    cpanm Digest::MD5
    '
done

# Temporary solution for Priam that crashes during the first job run
sudo mkdir $METAPIPE_DIR/metapipe/databases/priam/PRIAM_MAR15/PROFILES/LIBRARY
cd $METAPIPE_DIR/metapipe/databases/priam/PRIAM_MAR15/PROFILES
sudo chmod 777 -R .
unset FILELIST
declare -a FILELIST
for f in *; do
    if [ "$(echo "$f")" != "LIBRARY" ]; then
        FILELIST[${#FILELIST[@]}+1]="../"$(echo "$f");
    fi
done
printf "%s\n" "${FILELIST[@]}" > LIBRARY/profiles.list
cd LIBRARY
$METAPIPE_DIR/metapipe/tools/blast-legacy/bin/formatrpsdb -i profiles.list -o T -n PROFILE_EZ -t PRIAM_profiles_database
cd $METAPIPE_DIR

>| $METAPIPE_DIR/metapipe-tmp/assembly_running
for name in "${WORKER_HOSTS[@]}"; do
    echo "0" >> $METAPIPE_DIR/metapipe-tmp/assembly_running
done
cat $METAPIPE_DIR/metapipe-tmp/assembly_running

echo "METAPIPE_DIR=$METAPIPE_DIR" >> $SPARK_HOME/conf/spark-env.sh
