output "vpc_id" {
  value = var.vpc_id
}
output "name" {
  value = var.name
}
output "zone" {
  value = var.zone
}
output "cidr_zone" {
  value = var.cidr_zone
}
output "cidr" {
  value = var.cidr
}
output "instances" {
  value = { for index, instance in ibm_is_instance.zone : index => {
    floating_ip_address  = ibm_is_floating_ip.zone[index].address
    primary_ipv4_address = instance.primary_network_interface[0].primary_ipv4_address
    instance = instance
  } }
}
output subnet_available0_id {
  value = ibm_is_subnet.available0.id
  }

output "next_hop" {
  value = local.next_hop
}