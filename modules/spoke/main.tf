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

resource "ibm_is_vpc_routing_table" "spoke" {
  vpc                           = ibm_is_vpc.spoke.id
  name                          = var.name
  route_transit_gateway_ingress = false
  route_direct_link_ingress     = false
  route_vpc_zone_ingress        = false
}

module "spoke_zones" {
  for_each             = var.zones
  source               = "../spoke_zone"
  tags                 = var.tags
  vpc_id               = ibm_is_vpc.spoke.id
  vpc_routing_table_id = ibm_is_vpc_routing_table.spoke.routing_table
  resource_group_id    = var.resource_group_id
  image_id             = var.image_id
  profile              = var.profile
  keys                 = var.keys
  user_data            = var.user_data
  next_hop             = var.next_hops[each.key]
  name                 = each.value.name
  zone                 = each.value.zone
  cidr                 = each.value.cidr
  cidr_zone            = each.value.cidr_zone
}
