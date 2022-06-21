output "transit_zones" {
  value = { for tz_key, tz in module.transit_zones : tz_key => {
    vpc_id                       = tz.vpc_id
    subnet_available0_id         = tz.subnet_available0_id
    next_hop                     = tz.next_hop
    zone                         = tz.zone
    name                         = tz.name
    bastion_primary_ipv4_address = tz.bastion_primary_ipv4_address
    bastion_floating_ip_address  = tz.bastion_floating_ip_address
    firewalls = { for fw_key, fw in tz.firewalls : fw_key => {
      floating_ip_address  = fw.floating_ip_address
      primary_ipv4_address = fw.primary_ipv4_address
  } } } }
}
output "spokes" {
  value = { for spoke_key, spoke in module.spokes : spoke_key => {
    zones = { for zone_key, zone in spoke.spoke_zones : zone_key => {
      zone             = zone.zone
      subnet_id        = zone.subnet_id
      routing_table_id = zone.routing_table_id
    } }
    vpc_id = spoke.vpc_id
  } }
}

output "globals" {
  value = {
    prefix            = var.prefix
    region            = var.region
    resource_group_id = data.ibm_resource_group.all_rg.id
    keys              = [data.ibm_is_ssh_key.sshkey.id]
    image_id          = data.ibm_is_image.os.id
    profile           = local.profile
  }
}