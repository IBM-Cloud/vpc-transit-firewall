output "name" {
  value = var.name
}
output "spoke_zones" {
  value = { for zindex, zone in module.spoke_zones : zindex => {
    subnet_id        = zone.subnet_id
    zone             = zone.zone
    routing_table_id = zone.routing_table_id
  } }
}

output "vpc_id" {
  value = ibm_is_vpc.spoke.id
}