
META-pipe related contents in this folder.

List of currently required files to run the META-pipe:

_prepare.sh,
_test.sh,
_run.sh - scripts required for the Tool to send procedure calls.

_init.sh - common init variables to be sourced in the scripts above.

_run_execution.sh - script that launches META-pipe in functional analysis mode, called by _run.sh.
_run_assembly.sh - script that launches META-pipe in assembly mode, called by _run.sh.

metapipe-deps-current.tar.gz - META-pipe dependencies.

workflow-assembly-0.1-SNAPSHOT.jar - META-ppe executable.

conf.json - META-pipe config file prepared for use in cPouta.

blast-2.2.19-x64-linux.tar.gz,
ncbi-blast-2.4.0+-2.x86_64.rpm - Blast Legacy and latest, required temporarily, as long as it is missing in "metapipe-deps-current.tar.gz"
