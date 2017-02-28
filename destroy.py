#!/usr/bin/python3
import subprocess
import sys
import os

###########################################
######### Destroy infrastructure  #########
###########################################

error = subprocess.call('terraform destroy <<< "yes"', shell=True)

if error != 0:
	sys.exit(error)

###########################################
########### Remove created files ##########
###########################################

if os.path.exists('cluster_vars.yaml'):
	os.remove('cluster_vars.yaml')
if os.path.exists('ansible_inventory'):	
	os.remove('ansible_inventory')
