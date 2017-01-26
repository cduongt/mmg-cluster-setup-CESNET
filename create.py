#!/usr/bin/python3
import subprocess
import sys
import socket

###########################################
#### Creating instances with Terraform ####
###########################################

error = subprocess.call("terraform apply", shell=True)

if error != 0:
	sys.exit(error)

master_ip = (subprocess.check_output("terraform show | grep master_ip", shell=True)).decode('ascii')
master_ip = master_ip.split("=", 2)[1].strip()
node_ip = (subprocess.check_output("terraform show | grep node_ip", shell=True)).decode('ascii')
node_ip = node_ip.split("=", 2)[1].strip().strip("\x1b[0m\n").split(",")


###########################################
###########  Inventory file ###############
###########################################

ansible_hosts = open('ansible_inventory', 'w')

ansible_hosts.write('[all:vars]\n')
ansible_hosts.write('ansible_ssh_user=cloud-user\n')
ansible_hosts.write('ansible_sudo=true\n')
ansible_hosts.write('cluster_name=csc-cluster\n')
ansible_hosts.write('[masters]\n')
ansible_hosts.write(socket.gethostbyaddr(master_ip)[0] + ' ansible_ssh_host=' + master_ip + ' vm_group_name=master\n')
ansible_hosts.write('[nodes]\n[nodes:children]\ndisk\n[disk]\n')
for item in node_ip:
	ansible_hosts.write(socket.gethostbyaddr(item)[0] + ' ansible_ssh_host=' + item + ' vm_group_name=disk\n')

ansible_hosts.close()

###########################################
########## Cluster vars file ##############
###########################################

cluster_vars = open('clustervars.yaml', 'w')
terraform_config = open('mmg-cluster.tf', 'r')

cluster_vars.write('cluster_name: "csc-cluster"\n\n')
cluster_vars.write('master:\n')
cluster_vars.write('  invetory_group: masters\n')
cluster_vars.write('  auto_ip: yes\n')
cluster_vars.write('  flavor: \n')
cluster_vars.write('  volumes:\n')
cluster_vars.write('    - name: metadata\n')
cluster_vars.write('      size:\n')
cluster_vars.write('      pv_path: /dev/vdc\n\n')