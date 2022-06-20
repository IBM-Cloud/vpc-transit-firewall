output "name" {
  value = var.name
}
output "spoke_zones" {
  value = { for zindex, zone in module.spoke_zones : zindex => {
    subnet_id = zone.subnet_id
    zone      = zone.zone
  } }
}

output "vpc_id" {
  value = ibm_is_vpc.spoke.id
}