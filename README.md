mmg-cluster-setup
===================
This is tool for setting up Metapipe in OCCI enabled endpoint. Uses code from [mmg-cluster-setup](https://github.com/elixir-marine/mmg-cluster-setup).  
Currently in development.  

Requirements:
- Linux distribution, tested on Fedora 24
- [rOCCI CLI](https://github.com/EGI-FCTF/rOCCI-cli)
- X509 VOMS certificate
- [contextualisation file](https://wiki.egi.eu/wiki/FAQ10_EGI_Federated_Cloud_User#Contextualisation)
- Python 3
- [Terraform](https://www.terraform.io/downloads.html) and [OCCI plugin](https://github.com/cduongt/terraform/tree/occi) (OCCI plugin binaries will be available soon)
- Ansible

File structure:
- "mmg-cluster.tf": Contains Terraform configuration
- "pouta-ansible-cluster": Folder containing Ansible playbooks
- "create.py": Python script creating and provisioning Metapipe environment

What it can do:
- Create 1 master and x slave nodes with Terraform at OCCI endpoint (currently tested only in CESNET MetaCloud. Might not work at other endpoints due to different CentOS 7 images)
- Provision all hosts with Ansible, copy necessary files to run Metapipe

What is missing:
- Cleanup script
- Some Metapipe file dependencies
