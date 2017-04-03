resource "occi_virtual_machine" "master" {
	image_template = "http://occi.carach5.ics.muni.cz/occi/infrastructure/os_tpl#uuid_egi_centos_7_fedcloud_warg_149"
	resource_template = "http://fedcloud.egi.eu/occi/compute/flavour/1.0#large"
	endpoint = "https://carach5.ics.muni.cz:11443"
	name = "vm_cluster_master"
	x509 = "/tmp/x509up_u1000"
	init_file = "/home/cduongt/context"
	storage_size = 400
}

resource "occi_virtual_machine" "node" {
	image_template = "http://occi.carach5.ics.muni.cz/occi/infrastructure/os_tpl#uuid_egi_centos_7_fedcloud_warg_149"
	resource_template = "http://fedcloud.egi.eu/occi/compute/flavour/1.0#large"
	endpoint = "https://carach5.ics.muni.cz:11443"
	name = "vm_cluster_node"
	x509 = "/tmp/x509up_u1000"
	init_file = "/home/cduongt/context"
	count = 4
	storage_size = 200
}

output "master_ip" {
	value = "${occi_virtual_machine.master.ip_address}"
}

output "node_ip" {
	value = "${join(",",occi_virtual_machine.node.*.ip_address)}"
}

output "master_storage_size" {
	value = "${occi_virtual_machine.master.storage_size}"
}

output "node_storage_size" {
	value = "${occi_virtual_machine.node.0.storage_size}"
}
