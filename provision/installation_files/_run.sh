#!/bin/bash
source ~/provision/_init.sh

java -jar $METAPIPE_DIR/workflow-assembly-0.1-SNAPSHOT.jar validate

sleep 2

export JOB_TAG=$2

if [ "$1" != "assembly" ]; then
    nohup /bin/bash ~/provision/installation_files/_run_func_analysis.sh "$@" > /dev/null 2>&1 &
else
    nohup /bin/bash ~/provision/installation_files/_run_assembly.sh "${@:2}" > /dev/null 2>&1 &
fi
