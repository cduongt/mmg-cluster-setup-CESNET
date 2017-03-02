
# RUN ASSEMBLY: code to be changed when assembly is added

source ~/provision/_init.sh

ARG1=$1
ARG2=$2

unset ASSEMBLY_NODE
unset ASSEMBLY_NODE_INDEX
while [[ $ASSEMBLY_NODE != *"$CLUSTER_NAME"* ]]; do
    for (( i=1; i<=${#WORKER_HOSTS[*]}; i++ )); do
        if [[ $(sed $i'q;d' $METAPIPE_DIR/metapipe-tmp/assembly_running) == "0" ]]; then
            ASSEMBLY_NODE=${WORKER_HOSTS[$i]}
            ASSEMBLY_NODE_INDEX=$i
            sed -i $i"s/.*/1/" $METAPIPE_DIR/metapipe-tmp/assembly_running
            break
        fi
        echo "0" >> $METAPIPE_DIR/metapipe-tmp/assembly_running
    done
    if [[ $ASSEMBLY_NODE != *"$CLUSTER_NAME"* ]]; then
        sleep 3
    fi
done

# Temporary
ARG1=/export/share/installation_files/moose_S1_L001_R1_001_small.fastq
ARG2=/export/share/installation_files/moose_S1_L001_R2_001_small.fastq

ssh -n cloud-user@$ASSEMBLY_NODE "
    export PATH=$DEPENDENCIES_PATH:\$PATH
    java -jar $METAPIPE_DIR/workflow-assembly-0.1-SNAPSHOT.jar \
    assembly -1 $ARG1 -2 $ARG2 \
    --config-file $METAPIPE_DIR/.metapipe/conf.json \
    --attempt-id $(date +%s) \
    --num-threads $CORES_PER_EXECUTOR
"

sed -i $ASSEMBLY_NODE_INDEX's/.*/0/' $METAPIPE_DIR/metapipe-tmp/assembly_running


