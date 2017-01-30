# Setting up a bastion host in cPouta

http://en.wikipedia.org/wiki/Bastion_host

In case you don't have a readily available host for running OpenStack command line tools and Ansible,
you can set one up in your cPouta project through https://pouta.csc.fi

Log into https://pouta.csc.fi

If you are member of multiple projects, select the desired one from the drop down list on top left

Create a new security group called, for example, 'bastion'

  - go to *Access and Security -> Security groups -> Create Security Group*
  - add rules to allow ssh for yourself and other admins
  - normal users do not need to access this hosts
  - keep the access list as small as possible to minimize exposure

Create an access key if you don't already have one

  - go to *Access and Security -> Keypairs -> Create/Import Keypair*

Boot a new VM from the latest CentOS 7 image that is provided by CSC

  - go to *Instances -> Launch Instance*
  - pick a name for the VM, for example 'bastion'
  - Flavor: standard.tiny
  - Instance boot source: Image
  - Image Name: Latest public Centos image (CentOS-7.0 at the time of writing)
  - Keypair: select your key
  - Security Groups: select *default* and *bastion*
  - Network: select the desired network (you probably only have one, which is the default)
  - Launch

Associate a floating IP (allocate one for the project if you don't already have a spare)

Log in to the bastion host with ssh as *cloud-user*

    ssh cloud-user@86.50.1XX.XXX:

Install dependencies and otherwise useful packages

    sudo yum install -y \
        dstat lsof bash-completion time tmux git xauth \
        screen nano vim bind-utils nmap-ncat git \
        xauth firefox \
        python-pip python-devel python-setuptools python-virtualenvwrapper \
        libffi-devel openssl-devel

    sudo yum groupinstall -y "Development Tools"

update the system and reboot to bring the host up to date. Bonus: virtualenvwrapper gets activated

    sudo yum update -y && sudo reboot

Install the openstack python libraries via pip

    sudo pip install python-openstackclient
    sudo pip install python-novaclient

import your OpenStack command line access configuration


  - see https://research.csc.fi/pouta-credentials how to export the openrc
  - use scp to copy the file to bastion from your workstation::

    [me@workstation ~]$ scp openrc.sh cloud-user@86.50.1XX.XXX:
