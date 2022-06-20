# spokes
resource "ibm_is_vpc" "spoke" {
  name                      = var.name
  tags                      = var.tags
  resource_group            = var.resource_group_id
  address_prefix_management = "manual"
}

resource "ibm_tg_connection" "spoke" {
  network_type = "vpc"
  gateway      = var.tg_gateway_id
  name         = ibm_is_vpc.spoke.name
  network_id   = ibm_is_vpc.spoke.crn
}

module "spoke_zones" {
  for_each             = var.zones
  source               = "../spoke_zone"
  tags                 = var.tags
  vpc_id               = ibm_is_vpc.spoke.id
  vpc_default_routing_table               = ibm_is_vpc.spoke.default_routing_table
  spoke_routing        = var.spoke_routing
  resource_group_id    = var.resource_group_id
  image_id             = var.image_id
  profile              = var.profile
  keys                 = var.keys
  user_data            = var.user_data
  next_hop             = var.transit_zones[each.key].next_hop
  bastion_cidr         = "${var.transit_zones[each.key].bastion_primary_ipv4_address}/32"
  name                 = each.value.name
  zone                 = each.value.zone
  cidr                 = each.value.cidr
  cidr_zone            = each.value.cidr_zone
  cidr_transit         = each.value.cidr_transit
}
