# Hortonworks playbooks
These playbooks can be used to deploy a Spark and HDFS cluster based on Hortonworks distribution in cPouta. 
The bulk of installation is done with the official installer playbook.

## Software and technologies used

The procedure will use: 
* Ansible for setting up and configuring a basic cluster with one master and multiple slaves.
* Apache Ambari to set up Hortonworks Data Platform 

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
    - ambari server
    - ambari agents
    - internal DNS
- automates a hortonworks based spark and hdfs cluster setup using ambari blueprints
- configures persistent storage

### deprovision.yml

- used to tear the cluster resources down

## Example installation process

This is a log of an example installation of a proof of concept cluster with

- one master
    - public IP
    - one persistent volume for data + swap
- four nodes
    - one persistent volume for data + swap

### What will be deployed

The system will consist of the following VMs:

* bastion
* cluster-master
* cluster-node-[1..n]

**bastion**
* acts as a ssh jump host 

**cluster-master**
* runs Ambari
* runs HDP master processes (HDFS, MapReduce, YARN, Monitoring)
* will have a volume (=persistent storage) mounted on /hadoop

**cluster-nodes**
* run HDFS storage
* run MapReduce and YARN workers
* will have a volume mounted on /hadoop

Public IPs (floating IPs in OpenStack) are assigned to *bastion* and *cluster-master*. Although, it is 
recommended that cluster master and nodes are accessed only internally, through bastion.

All VMs will the default CentOS 7 image provided by CSC.  

### Security implications, recommendations and shortcomings

* You *must* protect Ambari admin account with a proper password, the notebooks have network access to it
* When you do not need the cluster anymore, shut the resources down (with the possible exclusion of *bastion*) 
* Keep a keen eye on the resources while they are active

### Prerequisites

Shell environment (Bastion host) with
- cPouta credentials
- ssh access to the internal network of your project
    - either run this on your bastion host
    - or set up ssh forwarding through your bastion host in your ~/.ssh/config

### Prepare the environment for setting up the virtual cluster

**NOTE: This step has to be done only when you are setting a cluster for the first time**

In this step we launch VMs in our cPouta project and configure them to act as a basis
for a simple cluster. You can run this on your management host, be it the bastion or your
laptop.

Make a python virtualenv called 'ansible-2.1' and populate it

    mkvirtualenv --system-site-packages ansible2
    pip install --upgrade pip setuptools
    pip install ansible==2.1
    pip install shade dnspython funcsigs functools32

Source your OpenStack cPouta access credentials (actual filename will vary)::

    source ~/openrc.sh
    nova image-list
    
Create a new key (if don't already have one) for the cluster (adapt the name) and upload it to OpenStack

    ssh-keygen -f ~/.ssh/id_rsa_mycluster
    nova keypair-add --pub-key ~/.ssh/id_rsa_mycluster.pub my_key

Clone this example repo

    git clone https://github.com/CSC-IT-Center-for-Science/pouta-ansible-cluster.git

Disable ssh host key checking (http://docs.ansible.com/ansible/intro_getting_started.html#host-key-checking).
Add an entry for all the hosts in your cPouta subnet. Use *ip* command to figure out your network address range.
Also adapt the IdentityFile -line to match the key you have generated.
    
    ip a
    
    vi ~/.ssh/config
    
    Host XX.XX.XX.*

        StrictHostKeyChecking no
        IdentitiesOnly yes
        IdentityFile ~/.ssh/id_rsa_mycluster
        
Change the permissions on the config file

    chmod 600 ~/.ssh/config

### Optional step: server group for node anti-affinity

Run the following command to create a server group with anti-affinity policy. By assigning
the VMs to this group, you make sure that they are running on separate physical hosts:

    nova server-group-create <cluster_name>-common anti-affinity

Make note of the server group id and set the server_group_id -variable for all the node
groups. You can later check the group membership for the VMs by running

    nova server-group-list

### Create a cluster config

In the ~/ directory, create a config file *cluster_vars.yaml* by copying one of the example files and modifying that.
For example, to provision a test cluster with master and four small nodes, take a copy the 
*cluster_vars.yaml.example-io-flavor* -file and change at least the following: 

    cluster_name: "spark-cluster"
    ssh_key: <my_key>
    ssd:
      flavor: io.160GB
      num_nodes: 4

### Run provisioning

Enable the virtualenv by `workon ansible2` (if not already enabled)

Source your OpenStack cPouta access credentials (actual filename will vary)::

    source ~/openrc.sh

Run the following command:

    nova server-group-create <cluster_name>-common anti-affinity

Now, Provision the VMs and associated resources

    ansible-playbook -v -e @cluster_vars.yaml ~/pouta-ansible-cluster/playbooks/hortonworks/provision.yml 

### Configure and Setup the virtual cluster for Spark and HDFS usage:

Once the above step completes successfully. Execute the following command:

    ansible-playbook -v -e @cluster_vars.yaml -i hortonworks-inventory ~/pouta-ansible-cluster/playbooks/hortonworks/configure.yml

Once the above command runs successfully, we need to access the Ambari web interface to track the progress. 
There are a few options for this:

**Option 1**. You can open a SOCKS proxy tunnel through bastion host with

    ssh -D 9999 cloud-user@<your-bastion-public-ip>

If you get this warning (even though you manage to login to bastion) `bind: Cannot assign requested address`, then please use the following command instead (which forces the SSH mechanism to use ipv4)

    ssh -4 -D 9999 cloud-user@<your-bastion-public-ip>

and then configure your (secondary) browser to use localhost:9999 as a SOCKS proxy server in proxy settings
Navigate to http://\<private-ip-of-the-cluster-master\>:8080

**Option 2**. You can open the port 8080 of spark-cluster master for access 

  - go to *Access and Security -> Security groups -> spark-cluster-master (depends on the cluster name) -> Manage Rules*
  - add rules (custom TCP) to access port 8080 for your IP and also for other admins
  - normal users do not need to access the ambari web ui
  - keep the access list as small as possible to minimize exposure

Use the public IP directly, navigate to http://\<public-ip-of-the-cluster-master\>:8080

Login to the Ambari dashboard using default credentials

    username: admin
    password: admin

You will be seeing several operations running in the dashboard (the top bar) along with several alers.
Wait till there are no more alerts. Zero alerts mean that the setup finished successfully.

Change the default password by selecting User + Group Management -> Users -> admin -> Change Password.

Try to ssh to the spark-cluster-master from the bastion host:

    ssh <private-ip-of-the-cluster-master>

Enable the usage of Spark and HDFS for cloud-user:

    sudo -u hdfs hadoop fs -mkdir /user/cloud-user
    sudo -u hdfs hadoop fs -chown -R cloud-user /user/cloud-user

### Try out Spark and HDFS on the cluster

You can run pySpark by running the following command:

    sh /usr/hdp/current/spark-client/bin/pyspark

This will however run it in local mode, to run it on the cluster use the following command:

    sh /usr/hdp/current/spark-client/bin/pyspark --master yarn

HDFS can be accessed by the following commands:

    hdfs dfs -ls /  (View contents of the HDFS file system)
    hdfs dfs -mkdir -p /some/dir  (Make directories)
    hdfs dfs -copyFromLocal src dest (Copy a file from local location to HDFS)
    hdfs dfs -copyToLocal src dest (Copy a file from HDFS to local)
    hdfs dfs -rmr /some/dir (Delete recursively)

*Some Important URLs (Private or Public IP of the cluster master will be used depending whether 
you are using SOCKS proxy tunnel or opening the ports, see above)*
  - yarn resource manager: \<cluster-master-ip\>:8088
  - spark history server: \<cluster-master-ip\>:18080

### Destroying the virtual cluster

To clean up the resources if you no longer require the cluster, or to have a clean slate for another deployment, there is 
a playbook called *deprovision.yml*. By default it does not do anything, all the actions have to be enabled
from the command line, just to be on a safe side.

Run these on your management/bastion host.
 
To remove the nodes and the master, but leave the HDFS data volumes and security groups:

    ansible-playbook -v \
        -e @cluster_vars.yaml \
        -e remove_masters=1 \
        -e remove_nodes=1 \
        ~/pouta-ansible-cluster/playbooks/hortonworks/deprovision.yml

To remove the nodes, master, all volumes and security groups:

    ansible-playbook -v \
        -e @cluster_vars.yaml \
        -e remove_masters=1 -e remove_master_volumes=1 \
        -e remove_nodes=1 -e remove_node_volumes=1 \
        -e remove_security_groups=1 \
        ~/pouta-ansible-cluster/playbooks/hortonworks/deprovision.yml

### Running a Jupyter notebook on the cluster

To run the Jupyter ipython notebook on the cluster. You should execute the following commands on the cluster master :

    sudo yum install gcc-c++ python-virtualenvwrapper
    source /etc/profile.d/virtualenvwrapper.sh
    mkvirtualenv jupyter --system-site-packages
    workon jupyter
    pip install --upgrade setuptools pip
    pip install jupyter
    pip install findspark

From now on, before running the notebook always run `workon jupyter` to activate the virtual environment.
Then, export the following variables:

    export SPARK_HOME='/usr/hdp/current/spark-client'
    export PYSPARK_SUBMIT_ARGS='--master yarn pyspark-shell'

Now run the notebook, using the following parameters:

    mkdir ~/notebooks 
    cd ~/notebooks
    jupyter notebook --ip 0.0.0.0 --port 9999 --no-browser

Now the notebook should be running on the cluster master on port 9999. Be sure to open the port in Openstack or setup a SOCKS proxy through your bastion host (like above)

To create SparkContext, execute the following commands in a jupyter notebook:

    import findspark
    findspark.init()
    import os
    os.environ['PYSPARK_PYTHON'] = '/usr/bin/python'

    from pyspark import SparkContext
    sc = SparkContext()

Once you have the SparkContext ready, your code will always be executed on the cluster.
