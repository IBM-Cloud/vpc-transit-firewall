output "vpc_id" {
  value = var.vpc_id
}
output "name" {
  value = var.name
}
output "zone" {
  value = var.zone
}
output "cidr" {
  value = var.cidr
}
output "subnet_id" {
  value = ibm_is_subnet.zone.id
}
output "routing_table_id" {
  value = var.spoke_routing ? ibm_is_vpc_routing_table.spoke[0].routing_table : ""
}