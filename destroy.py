#!/usr/bin/python3
import subprocess
import sys
import os

###########################################
######### Destroy infrastructure  #########
###########################################

print('Destroying infrastructure')

error_code = subprocess.call('terraform destroy <<< "yes"', shell=True)

if error_code != 0:
    sys.exit(error_code)

if os.path.exists('terraform.tfstate'):
    os.remove('terraform.tfstate')

if os.path.exists('terraform.tfstate.backup'):
    os.remove('terraform.tfstate.backup')

###########################################
########### Remove created files ##########
###########################################

print('Cleaning up files')

if os.path.exists('cluster_vars.yaml'):
    os.remove('cluster_vars.yaml')
if os.path.exists('ansible_inventory'):
    os.remove('ansible_inventory')
