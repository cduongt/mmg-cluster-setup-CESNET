#!/usr/bin/python3
import os
import subprocess
import sys
import time

def print_help():
    print("Correct usage of this script:")
    print("./run.py job-tag")


if not os.path.exists('ansible_inventory'):
    print('Virtual machines were not created. Did you run "create.py" before?')
    sys.exit(1)

if len(sys.argv) != 2:
    print_help()
    sys.exit(0)

job_tag = sys.argv[1]

master_ip = (subprocess.check_output(
    "terraform show | grep master_ip", shell=True)).decode('ascii')
master_ip = master_ip.split("=", 2)[1].strip()

###########################################
############## Run Metapipe ###############
###########################################

error_code = subprocess.call(
    "ssh -o StrictHostKeyChecking=no cloud-user@" +
    master_ip +
    " nohup provision/installation_files/_run.sh func_analysis " +
    job_tag + " > metapipe.log 2>&1 &", shell=True)

if error_code != 0:
    print('Error while trying to run metapipe.', file=sys.stderr)
    sys.exit(error_code)

time.sleep(10)
print('Web UI is running at ' + master_ip + ':8080')