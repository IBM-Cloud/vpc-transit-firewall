# spoke routing through the subnet

# Prefix for the entire zone not just the VPC
resource "ibm_is_vpc_address_prefix" "zone" {
  vpc  = var.vpc_id
  name = var.name
  zone = var.zone
  cidr = var.cidr
}

resource "ibm_is_vpc_routing_table" "spoke" {
  count = var.spoke_routing ? 1 : 0
  vpc                           = var.vpc_id
  name                          = var.name
  route_transit_gateway_ingress = false
  route_direct_link_ingress     = false
  route_vpc_zone_ingress        = false
}


resource "ibm_is_vpc_routing_table_route" "zone" {
  count = var.spoke_routing ? 1 : 0
  vpc           = var.vpc_id
  routing_table = ibm_is_vpc_routing_table.spoke[0].routing_table
  zone          = var.zone
  name          = var.name
  destination   = "0.0.0.0/0" # allow spoke to spoke and external access through the firewall
  # destination   = var.cidr_zone # allow only spoke to spoke access through firewall
  action   = "deliver"
  next_hop = var.next_hop
}

# spoke to transit bastion is not through the firewall.
# This allows the spokes to be accessed via ssh from the transit server
resource "ibm_is_vpc_routing_table_route" "bastion" {
  count = var.spoke_routing ? 1 : 0
  vpc           = var.vpc_id
  routing_table = ibm_is_vpc_routing_table.spoke[0].routing_table
  zone          = var.zone
  name          = "${var.name}-transit-bastion"
  destination   = var.bastion_cidr
  action        = "delegate"
  next_hop      = "0.0.0.0"
}

resource "ibm_is_subnet" "zone" {
  tags            = var.tags
  name            = ibm_is_vpc_address_prefix.zone.name
  vpc             = var.vpc_id
  zone            = var.zone
  ipv4_cidr_block = var.cidr
  routing_table   = var.spoke_routing ? ibm_is_vpc_routing_table.spoke[0].routing_table : var.vpc_default_routing_table
}