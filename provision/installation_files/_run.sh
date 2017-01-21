
source _init.sh

java -jar $METAPIPE_DIR/workflow-assembly-0.1-SNAPSHOT.jar validate

sleep 2

if [ "$1" != "assembly" ]; then
    source _run_execution.sh "$@"
else
    source _run_assembly.sh "${@:2}"
fi