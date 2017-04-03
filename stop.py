#!/usr/bin/python3
import os
import subprocess
import sys

if not os.path.exists('ansible_inventory'):
    print('Virtual machines were not created. Did you run "create.py" before?')
    sys.exit(1)

master_ip = (subprocess.check_output(
    "terraform show | grep master_ip", shell=True)).decode('ascii')
master_ip = master_ip.split("=", 2)[1].strip()

error_code = subprocess.call(
    "ssh -o StrictHostKeyChecking=no cloud-user@" +
    master_ip +
    " source provision/installation_files/_stop.sh", shell=True)

if error_code != 0:
    print('Error while trying to stop Metapipe.', file=sys.stderr)
    sys.exit(error_code)