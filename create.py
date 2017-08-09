#!/usr/bin/python3
import json
import os
import re
import socket
import subprocess
import sys


###########################################
############ Helper functions #############
###########################################

def get_terraform_param(param):
    param_output = (subprocess.check_output(
        'terraform show -no-color | grep ' + param, shell=True)).decode('ascii')
    return param_output.split('=', 2)[1].strip()
    
def get_description_json(id, x509, endpoint):
    return json.loads(subprocess.check_output(
        'occi -e ' + endpoint + ' -n x509 -x ' + x509 +' -X -a describe -r ' + id + ' -o json',
        shell=True).decode('utf-8'))

###########################################
###### Some constants for parameters ######
###########################################

metapipe_download = 'http://stoor124.meta.zcu.cz:15014/'
metapipe_dependencies_file = 'metapipe-dependencies.tar.gz'
workflow_file = 'workflow-assembly-0.1-SNAPSHOT.jar'

###########################################
#### Creating instances with Terraform ####
###########################################

error_code = subprocess.call("terraform apply", shell=True)

if error_code != 0:
    print('Error while creating virtual machines.', file=sys.stderr)
    subprocess.call('./destroy.py', shell=True)
    sys.exit(error_code)

master_ip = get_terraform_param('master_ip')
node_ip = get_terraform_param('node_ip').split(',')

###########################################
###########  Inventory file ###############
###########################################

ansible_hosts = open('ansible_inventory', 'w')

ansible_hosts.write('[all:vars]\n')
ansible_hosts.write('ansible_ssh_user=cloud-user\n')
ansible_hosts.write('ansible_sudo=true\n')
ansible_hosts.write('cluster_name=metapipe-cluster\n')
ansible_hosts.write('[masters]\n')
ansible_hosts.write(socket.gethostbyaddr(master_ip)[0] +
                    ' ansible_ssh_host=' + master_ip + ' vm_group_name=master\n')
ansible_hosts.write('[nodes]\n[nodes:children]\ndisk\n[disk]\n')
for item in node_ip:
    ansible_hosts.write(socket.gethostbyaddr(
        item)[0] + ' ansible_ssh_host=' + item + ' vm_group_name=disk\n')

ansible_hosts.close()

###########################################
##############  Slave list  ###############
###########################################

slaves = open('provision/slaves', 'w')

for item in node_ip:
    slaves.write(socket.gethostbyaddr(item)[0] + '\n')

slaves.close()

###########################################
########### Cluster vars file #############
###########################################

x509 = get_terraform_param('proxy_file')
endpoint = get_terraform_param('occi_endpoint')
master_id = get_terraform_param('master_id')
node_id = get_terraform_param('node_id')
storage_link_id = get_terraform_param('master_storage_link')

master_description = get_description_json(master_id, x509, endpoint)
node_description = get_description_json(node_id, x509, endpoint)

master_cores = master_description[0]['attributes']['occi']['compute']['cores']
master_memory = master_description[0]['attributes']['occi']['compute']['memory']
for link in master_description[0]['links']:
    if 'network' in link['kind']:
        network_id = link['attributes']['occi']['core']['target']

network_description = get_description_json(network_id, x509, endpoint)
network_range = network_description[0]['attributes']['occi']['network']['address']

node_cores = node_description[0]['attributes']['occi']['compute']['cores']
node_memory = node_description[0]['attributes']['occi']['compute']['memory']

# workaround around incosistent MB/GB output on sites
if master_memory < 512.0:
    master_memory = master_memory * 1000
if node_memory < 512.0:
    node_memory = node_memory * 1000

storage_description = get_description_json(storage_link_id, x509, endpoint)
storage_mount = storage_description[0]['attributes']['occi']['storagelink']['deviceid']

cluster_vars = open('cluster_vars.yaml', 'w')
master_storage_size = get_terraform_param('master_storage_size')
node_storage_size = get_terraform_param('node_storage_size')

cluster_vars.write('cluster_name: "metapipe-cluster"\n\n')
cluster_vars.write('nfs_shares:\n')
cluster_vars.write('  - directory: /export/share\n')
cluster_vars.write('    export_options: "*(rw)"\n\n')
cluster_vars.write('master:\n')
cluster_vars.write('  invetory_group: masters\n')
cluster_vars.write('  auto_ip: yes\n')
cluster_vars.write('  cores: ' + str(master_cores) + '\n')
cluster_vars.write('  memory_squid: ' + str(int(round(master_memory // 2.0))) + '\n')
cluster_vars.write('  network_range: ' + network_range + '\n')
cluster_vars.write('  volumes:\n')
cluster_vars.write('    - name: metadata\n')
cluster_vars.write('      size: ' + master_storage_size + '\n')
cluster_vars.write('      pv_path: ' + storage_mount + '\n\n')
cluster_vars.write('  filesystems:\n')
cluster_vars.write('    - name: swap\n')
cluster_vars.write('      volume: metadata\n')
cluster_vars.write('      size: "2%VG"\n')
cluster_vars.write('      fstype: swap\n\n')
cluster_vars.write('    - name: hadoop\n')
cluster_vars.write('      volume: metadata\n')
cluster_vars.write('      mount_path: "/hadoop"\n')
cluster_vars.write('      size: "17%VG"\n')
cluster_vars.write('      fstype: xfs\n')
cluster_vars.write('      mkfs_opts: ""\n\n')
cluster_vars.write('    - name: nfs_share\n')
cluster_vars.write('      volume: metadata\n')
cluster_vars.write('      mount_path: "/export/share"\n')
cluster_vars.write('      size: "80%VG"\n')
cluster_vars.write('      fstype: "btrfs"\n')
cluster_vars.write('      mount_opts: "defaults,compress=lzo"\n\n')
cluster_vars.write('node_groups:\n')
cluster_vars.write('  - disk\n\n')
cluster_vars.write('disk:\n')
cluster_vars.write('  num_vms: ' + str(len(node_ip)) + '\n')
cluster_vars.write('  cores: ' + str(node_cores) + '\n')
cluster_vars.write('  memory: ' + str(int(node_memory)) + '\n')
cluster_vars.write('  network_range: ' + network_range + '\n')
cluster_vars.write('  volumes:\n')
cluster_vars.write('    - name: datavol\n')
cluster_vars.write('      size: ' + node_storage_size + '\n')
cluster_vars.write('      pv_path: ' + storage_mount + '\n\n')
cluster_vars.write('  filesystems:\n')
cluster_vars.write('    - name: swap\n')
cluster_vars.write('      volume: datavol\n')
cluster_vars.write('      size: "2%VG"\n')
cluster_vars.write('      fstype: swap\n\n')
cluster_vars.write('    - name: hadoop_disk\n')
cluster_vars.write('      volume: datavol\n')
cluster_vars.write('      size: "97%VG"\n')
cluster_vars.write('      mount_path: "/hadoop/disk"\n')
cluster_vars.write('      fstype: xfs\n')

cluster_vars.close()

###########################################
##############  Templates  ################
###########################################

if os.path.exists('provision/_init.sh'):
    os.remove('provision/_init.sh')

init = open('provision/_init.sh', 'a')
init_template = open('templates/_init.sh')

init.write('CORES_MASTER=' + str(master_cores) + '\n')
init.write('RAM_MASTER=' + str(int(round(master_memory // 2000.0))) + '\n')
init.write('CORES_PER_SLAVE=' + str(node_cores) + '\n')
init.write('RAM_PER_SLAVE=' + str(int(node_memory // 1000.0)) + '\n')
init.write('CORES_PER_EXECUTOR=' + str(node_cores) + '\n')
init.write('EXECUTORS_PER_SLAVE=$(($CORES_PER_SLAVE / $CORES_PER_EXECUTOR))\n')
init.write('RAM_PER_EXECUTOR=$((($RAM_PER_SLAVE / $EXECUTORS_PER_SLAVE)-1))\n')

for line in init_template.readlines():
    init.write(line)

init.close()
init_template.close()

###########################################
###############  Ansible  #################
###########################################

error_code = subprocess.call(
    "ansible-playbook -v -e @cluster_vars.yaml -i ansible_inventory pouta-ansible-cluster/playbooks/hortonworks/configure.yml", shell=True)

if error_code != 0:
    print('Ansible ended with error, cleaning up.', file=sys.stderr)
    subprocess.call('./destroy.py', shell=True)
    sys.exit(error_code)

###########################################
##############  Copy files  ###############
###########################################

error_code = subprocess.call(
    "scp -r -o StrictHostKeyChecking=no provision/ cloud-user@" +
    master_ip + ":/home/cloud-user", shell=True)

if error_code != 0:
    print('Error while copying files, cleaning up.', file=sys.stderr)
    subprocess.call('./destroy.py', shell=True)
    sys.exit(error_code)

###########################################
########## Setup Spark cluster ############
###########################################

error_code = subprocess.call(
    "ssh -o StrictHostKeyChecking=no cloud-user@" +
    master_ip + " source provision/_setup_cluster.sh", shell=True)

if error_code != 0:
    print('Error while setting up cluster, cleaning up.', file=sys.stderr)
    subprocess.call('./destroy.py', shell=True)
    sys.exit(error_code)

###########################################
###### Prepare basic cluster config #######
###########################################

error_code = subprocess.call(
    "ssh -o StrictHostKeyChecking=no cloud-user@" +
    master_ip + " source provision/installation_files/_prepare.sh", shell=True)

if error_code != 0:
    print('Error while trying to prepare config.', file=sys.stderr)
    sys.exit(error_code)