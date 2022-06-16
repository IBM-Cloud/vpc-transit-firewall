/*
todo
output "script_cloud" {
  value = templatefile("${path.module}/script.tftpl", {
    transit_zones = module.transit_zones
    transit_vpc   = ibm_is_vpc.transit
    spokes        = module.spokes
  })
}
*/

output "transit_zones" {
  value = { for tz_key, tz in module.transit_zones : tz_key => {
    vpc_id               = tz.vpc_id
    subnet_available0_id = tz.subnet_available0_id
    next_hop = tz.next_hop
    instances = { for instance_key, instance in tz.instances : instance_key => {
      floating_ip_address  = instance.floating_ip_address
      primary_ipv4_address = instance.primary_ipv4_address
  } } } }
}
output "spokes" {
  value = { for spoke_key, spoke in module.spokes : spoke_key => {
    vpc_id = spoke.vpc_id
    zones = { for zone_key, zone in spoke.spoke_zones : zone_key => {
      zone      = zone.zone
      subnet_id = zone.subnet_id
    } }
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