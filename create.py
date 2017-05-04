#!/usr/bin/python3
import re
import socket
import subprocess
import sys

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

master_ip = (subprocess.check_output(
    "terraform show | grep master_ip", shell=True)).decode('ascii')
master_ip = master_ip.split("=", 2)[1].strip()
node_ip = (subprocess.check_output(
    "terraform show | grep node_ip", shell=True)).decode('ascii')
node_ip = node_ip.split("=", 2)[1].strip().split(",")

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
########### Cluster vars file #############
###########################################

cluster_vars = open('cluster_vars.yaml', 'w')
master_storage_size = (subprocess.check_output(
    "terraform show | grep master_storage_size", shell=True)).decode('ascii')
master_storage_size = master_storage_size.split("=", 2)[1].strip()
node_storage_size = (subprocess.check_output(
    "terraform show | grep node_storage_size", shell=True)).decode('ascii')
node_storage_size = node_storage_size.split("=", 2)[1].strip()
node_storage_size = re.sub('\x1b[^m]*m', '', node_storage_size)

cluster_vars.write('cluster_name: "csc-cluster"\n\n')
cluster_vars.write('nfs_shares:\n')
cluster_vars.write('  - directory: /export/share\n')
cluster_vars.write('    export_options: "*(rw)"\n\n')
cluster_vars.write('master:\n')
cluster_vars.write('  invetory_group: masters\n')
cluster_vars.write('  auto_ip: yes\n')
cluster_vars.write('  volumes:\n')
cluster_vars.write('    - name: metadata\n')
cluster_vars.write('      size: ' + master_storage_size + '\n')
cluster_vars.write('      pv_path: /dev/vdc\n\n')
cluster_vars.write('  filesystems:\n')
cluster_vars.write('    - name: swap\n')
cluster_vars.write('      volume: metadata\n')
cluster_vars.write('      size: "2%VG"\n')
cluster_vars.write('      fstype: swap\n\n')
cluster_vars.write('    - name: hadoop\n')
cluster_vars.write('      volume: metadata\n')
cluster_vars.write('      mount_path: "/hadoop"\n')
cluster_vars.write('      size: "47%VG"\n')
cluster_vars.write('      fstype: xfs\n')
cluster_vars.write('      mkfs_opts: ""\n\n')
cluster_vars.write('    - name: nfs_share\n')
cluster_vars.write('      volume: metadata\n')
cluster_vars.write('      mount_path: "/export/share"\n')
cluster_vars.write('      size: "50%VG"\n')
cluster_vars.write('      fstype: "btrfs"\n')
cluster_vars.write('      mount_opts: "defaults,compress=lzo"\n\n')
cluster_vars.write('node_groups:\n')
cluster_vars.write('  - disk\n\n')
cluster_vars.write('disk:\n')
cluster_vars.write('  num_vms: ' + str(len(node_ip)) + '\n')
cluster_vars.write('  volumes:\n')
cluster_vars.write('    - name: datavol\n')
cluster_vars.write('      size: ' + node_storage_size + '\n')
cluster_vars.write('      pv_path: "/dev/vdc"\n\n')
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
######## Get metapipe dependencies ########
###########################################

error_code = subprocess.call(
    "ssh -o StrictHostKeyChecking=no cloud-user@" + master_ip +
    " wget --progress=bar:force " +
    metapipe_download + metapipe_dependencies_file +
    " -P /export/share", shell=True)

if error_code != 0:
    print('Error while getting ' + metapipe_dependencies_file + ', cleaning up.', file=sys.stderr)
    subprocess.call('./destroy.py', shell=True)
    sys.exit(error_code)

error_code = subprocess.call(
    "ssh -o StrictHostKeyChecking=no cloud-user@" + master_ip +
    " wget --progress=bar:force " +
    metapipe_download + workflow_file +
    " -P /export/share", shell=True)

if error_code != 0:
    print('Error while getting workflow-assembly-0.1-SNAPSHOT.jar, cleaning up.', file=sys.stderr)
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