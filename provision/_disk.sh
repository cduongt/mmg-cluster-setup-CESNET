#!/usr/bin/env bash

# Arg 1: Disk ID, Arg 2: operation, Arg 3: Disk Name

DISK_ID="$1"
DISK_NAME="$3"

while read SERIAL; do
    echo "Found device with ID: " $SERIAL
    SERIAL=${SERIAL#virtio-}
    if [[ $DISK_ID == *$SERIAL* ]]; then
        DEVICE=$(readlink -f /dev/disk/by-id/*$SERIAL);
        echo $DEVICE" "$SERIAL;
        break
    fi
done <<< "$(ls /dev/disk/by-id/)"

if [ -z $DEVICE ]; then
    echo "Disk not found! Check the correctness of the disk name in the argument, ensure the disk is attached to the VM."
    exit 0
fi

#unset DISK
#while read x; do
#    echo "Found (mounted or unmounted) partition: " $x
#    if [[ $x == *$DISK_NAME* ]]; then
#        DEVICE=$(echo "$x" | grep --color=NEVER -o '/dev/\w*');
#        break
#    fi
#done <<< "$(sudo blkid -c /dev/null)"
#if [ -z "$VAR" ]; then
#    echo "Disk not found! Check the correctness of the disk name in the argument, ensure the disk is attached to the VM."
#    exit 0
#fi

echo $DEVICE

if [ "$2" == "create" ]; then
    sudo parted -l
    sudo parted -s -a optimal $DEVICE mklabel gpt
    sudo parted -s -a optimal $DEVICE mkpart primary 0% 100%
    sudo mkfs.ext4 ${DEVICE}1
    sudo e2label ${DEVICE}1 $DISK_NAME
    #echo "LABEL=$DISK_NAME    /media/$DISK_NAME    ext4    defaults    0    0" | sudo tee --append /etc/fstab
    echo "Partition created."
    sudo parted -l | grep --color=NEVER '/dev/'
elif [ "$2" == "mount" ]; then
    sudo mkdir -p /media/$DISK_NAME
    sudo mount ${DEVICE}1 /media/$DISK_NAME
    echo "Partition mounted."
    df -aTh | grep --color=NEVER "/dev/v"
elif [ "$2" == "unmount" ]; then
    sudo umount ${DEVICE}1
    echo "Partition unmounted."
    df -aTh | grep --color=NEVER "/dev/v"
else
    echo "Unknown parameter"
    exit 0
fi






## Ops to do, Bastion:
#sudo mkdir /media/$DISK_NAME/sw-packed
#sudo mkdir /media/$DISK_NAME/sw-unpacked
#sudo cp -v ~/installation_files/* /media/$DISK_NAME/sw-packed
#du -hs /media/$DISK_NAME/sw-packed
#sudo tar xvf ~/installation_files/metapipe-deps-current.tar.gz -C /media/$DISK_NAME/sw-unpacked
#du -hs /media/$DISK_NAME/sw-unpacked
#
##Ops to do, Master:
##sudo mkdir /data/sw
##sudo cp -v /media/$DISK_NAME/sw-packed/* /data/sw
#sudo tar xvf /media/$DISK_NAME/sw-packed/metapipe-deps-current.tar.gz -C $METAPIPE_DIR
#sudo cp /media/$DISK_NAME/sw-packed/*.sh $METAPIPE_DIR
#sudo cp /media/$DISK_NAME/sw-packed/conf.json $METAPIPE_DIR
#sudo cp /media/$DISK_NAME/sw-packed/blast-2.2.19-x64-linux.tar.gz $METAPIPE_DIR
#sudo cp /media/$DISK_NAME/sw-packed/ncbi-blast-2.4.0+-2.x86_64.rpm $METAPIPE_DIR
#sudo cp /media/$DISK_NAME/sw-packed/workflow-assembly-0.1-SNAPSHOT.jar $METAPIPE_DIR