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
  for_each                     = local.cidr_transit_vpc
  source                       = "./modules/transit_zone"
  tags                         = local.tags
  vpc_id                       = ibm_is_vpc.transit.id
  vpc_default_routing_table    = ibm_is_vpc.transit.default_routing_table
  resource_group_id            = data.ibm_resource_group.all_rg.id
  image_id                     = data.ibm_is_image.os.id
  profile                      = local.profile
  keys                         = [data.ibm_is_ssh_key.sshkey.id]
  firewall_lb                  = var.firewall_lb
  number_of_firewalls_per_zone = var.number_of_firewalls_per_zone
  user_data                    = local.user_data
  use_routing                  = var.use_routing
  name                         = each.value.name
  zone                         = each.value.zone
  cidr_zone                    = each.value.cidr_zone
  cidr                         = each.value.cidr
}


module "spokes" {
  for_each          = local.cidr_spoke_vpc
  source            = "./modules/spoke"
  tags              = local.tags
  tg_gateway_id     = ibm_tg_gateway.region.id
  use_routing       = var.use_routing
  resource_group_id = data.ibm_resource_group.all_rg.id
  image_id          = data.ibm_is_image.os.id
  profile           = local.profile
  keys              = [data.ibm_is_ssh_key.sshkey.id]
  user_data         = local.user_data
  name              = each.value.name
  zones             = each.value.zones
  transit_zones     = module.transit_zones
}