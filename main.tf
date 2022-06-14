locals {
  cloud_transit_name = "${var.prefix}-transit"
}

resource "ibm_tg_gateway" "region" {
  name           = "${var.prefix}-tgw"
  location       = var.region
  global         = false
  resource_group = data.ibm_resource_group.all_rg.id
  tags           = local.tags
}

resource "ibm_is_vpc" "transit" {
  name                      = local.cloud_transit_name
  tags                      = local.tags
  resource_group            = data.ibm_resource_group.all_rg.id
  address_prefix_management = "manual"
}

resource "ibm_tg_connection" "zone" {
  network_type = "vpc"
  gateway      = ibm_tg_gateway.region.id
  name         = ibm_is_vpc.transit.name
  network_id   = ibm_is_vpc.transit.crn
}

resource "ibm_is_vpc_routing_table" "transit" {
  vpc                           = ibm_is_vpc.transit.id
  name                          = ibm_is_vpc.transit.name
  route_transit_gateway_ingress = true
  route_direct_link_ingress     = false
  route_vpc_zone_ingress        = false
}

# todo
locals {
  user_data = <<-EOT
  #!/bin/bash
  set -x
  export DEBIAN_FRONTEND=noninteractive
  apt -qq -y update < /dev/null
  apt -qq -y install net-tools nginx npm < /dev/null
  EOT
}

module "transit_zones" {
  for_each             = local.cidr_transit_vpc
  source               = "./modules/transit_zone"
  tags                 = local.tags
  vpc_id               = ibm_is_vpc.transit.id
  vpc_routing_table_id = ibm_is_vpc_routing_table.transit.routing_table
  resource_group_id    = data.ibm_resource_group.all_rg.id
  image_id             = data.ibm_is_image.os.id
  profile              = local.profile
  keys                 = [data.ibm_is_ssh_key.sshkey.id]
  user_data            = local.user_data
  name                 = each.value.name
  zone                 = each.value.zone
  cidr_zone            = each.value.cidr_zone
  cidr                 = each.value.cidr
}


module "spokes" {
  for_each          = local.cidr_spoke_vpc
  source            = "./modules/spoke"
  tags              = local.tags
  tg_gateway_id     = ibm_tg_gateway.region.id
  resource_group_id = data.ibm_resource_group.all_rg.id
  image_id          = data.ibm_is_image.os.id
  profile           = local.profile
  keys              = [data.ibm_is_ssh_key.sshkey.id]
  user_data         = local.user_data
  name              = each.value.name
  zones             = each.value.zones
  next_hops         = { for tzone_id, tzone in module.transit_zones : tzone_id => tzone.next_hop }
}