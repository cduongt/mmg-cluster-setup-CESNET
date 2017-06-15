resource "occi_virtual_machine" "master" {
	image_template = "http://occi.carach5.ics.muni.cz/occi/infrastructure/os_tpl#uuid_fe71524e_66d3_5d09_8375_c5510ed5ccba_warg_default_shared_230"
	resource_template = "http://fedcloud.egi.eu/occi/compute/flavour/1.0#large"
	endpoint = "https://carach5.ics.muni.cz:11443"
	name = "vm_cluster_master"
	x509 = "/tmp/x509up_u1000"
	init_file = "/home/cduongt/context"
	storage_size = 300
}

resource "occi_virtual_machine" "node" {
	image_template = "http://occi.carach5.ics.muni.cz/occi/infrastructure/os_tpl#uuid_fe71524e_66d3_5d09_8375_c5510ed5ccba_warg_default_shared_230"
	resource_template = "http://fedcloud.egi.eu/occi/compute/flavour/1.0#large"
	endpoint = "https://carach5.ics.muni.cz:11443"
	name = "vm_cluster_node"
	x509 = "/tmp/x509up_u1000"
	init_file = "/home/cduongt/context"
	count = 4
	storage_size = 50
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
