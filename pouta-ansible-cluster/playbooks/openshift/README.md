# OpenShift Origin playbooks

These playbooks can be used to assist deploying an OpenShift Origin cluster in cPouta. The bulk of installation
is done with the official [installer playbook](https://github.com/openshift/openshift-ansible).

*NOTE:* This document is not a complete guide, but mostly a checklist for persons already knowing
what to do or willing to learn. Do not expect that after completing the steps you have a usable OpenShift environment.

## Playbooks

### provision.yml

- takes care of creating the resources in cPouta project
    - VMs with optionally booting from volume
    - volumes for persistent storage
    - common and master security groups
    
- writes an inventory file to be used by later stages

### configure.yml

- adds basic tools
- installs and configures
    - docker
    - internal DNS
- configures persistent storage

### deprovision.yml

- used to tear the cluster resources down

## Example installation process

This is a log of an example installation of a proof of concept cluster with

- one master
    - public IP
    - two persistent volumes, one for docker + swap, one for NFS persistent storage
- four nodes
    - one persistent volume for docker + swap

### Prerequisites

Shell environment with
- OpenStack credentials for cPouta 
- python virtualenvironment with ansible>=2.1.0, shade and dnspython
- venv should have latest setuptools and pip (pip install --upgrade setuptools pip)
- ssh access to the internal network of your project
    - either run this on your bastion host
    - or set up ssh forwarding through your bastion host in your ~/.ssh/config
    - please test ssh manually after provisioning 

For automatic, self-provisioned app routes to work, you will need a wildcard DNS CNAME for your master's public IP.
 
In general, see https://docs.openshift.org/latest/install_config/install/prerequisites.html

### Clone playbooks

Clone the necessary playbooks from GitHub (here we assume they go under ~/git)
    
    $ cd ~/git
    $ git clone https://github.com/CSC-IT-Center-for-Science/pouta-ansible-cluster
    $ git clone https://github.com/openshift/openshift-ansible.git
    
The following is a temporary fix for creating NFS volumes

    $ git clone https://github.com/tourunen/openshift-ansible.git openshift-ansible-tourunen
    $ cd openshift-ansible-tourunen
    $ git checkout nfs_fixes

### Create a cluster config

Decide a name for your cluster, create a new directory and copy the example config file and modify that

    $ cd
    $ mkdir YOUR_CLUSTER_NAME
    $ cd YOUR_CLUSTER_NAME
    $ cp ~/git/pouta-ansible-cluster/playbooks/openshift/example_cluster_vars.yaml cluster_vars.yaml

Change at least the following config entries:
    cluster_name: "YOUR_CLUSTER_NAME" 
    ssh_key: "bastion-key"

    

### Run provisioning

First provision the VMs and associated resources

    $ workon ansible-2.1
    $ ansible-playbook -v -e @cluster_vars.yaml ~/git/pouta-ansible-cluster/playbooks/openshift/provision.yml 

Then prepare the VMs for installation

    $ ansible-playbook -v -e @cluster_vars.yaml -i openshift-inventory ~/git/pouta-ansible-cluster/playbooks/openshift/configure.yml
     
Finally run the installer (this will take a while).
    
    $ ansible-playbook -v -b -i openshift-inventory ~/git/openshift-ansible/playbooks/byo/config.yml

Also, create the persistent volumes at this point. Edit the playbook to suit your needs, then run it. Note that if you
want to deploy a registry with persistent storage, you will need at least one pvol to hold the data for the registry.

    $ vi ~/git/openshift-ansible-tourunen/setup_lvm_nfs.yml
    $ ansible-playbook -v -i openshift-inventory ~/git/openshift-ansible-tourunen/setup_lvm_nfs.yml

### Configure the cluster

Login to the master, switch to root

    $ ssh cloud-user@your.masters.internal.ip
    $ sudo -i
    
Add the persistent volumes that were created earlier to OpenShift

    $ for vol in persistent-volume.pvol*; do oc create -f $vol; done

Deploy registry with persistent storage. Note that you need a pvol that is at least 200GB for this.

    $ oc adm manage-node $HOSTNAME.novalocal --schedulable=true
    $ oc delete all --selector=docker-registry=default
    $ oc adm registry --selector=region=infra
    $ oc volume dc/docker-registry --remove --name=registry-storage 
    $ oc volume dc/docker-registry --add --mount-path=/registry --overwrite --name=registry-storage -t pvc --claim-size=200Gi 

Installer already creates a deployment config for router, just scale it up
    
    $ oc scale dc/router --replicas=1 

Disable further deployments on master

    $ oc adm manage-node $HOSTNAME.novalocal --schedulable=false

Add a user
    
    $ htpasswd -c /etc/origin/master/htpasswd alice

## Further actions

- open security groups
- start testing and learning
- get a proper certificate for master
