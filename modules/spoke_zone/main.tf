# transit zone

# Prefix for the entire zone not just the VPC
resource "ibm_is_vpc_address_prefix" "zone" {
  vpc  = var.vpc_id
  name = var.name
  zone = var.zone
  cidr = var.cidr
}

resource "ibm_is_vpc_routing_table_route" "zone" {
  vpc           = var.vpc_id
  routing_table = var.vpc_routing_table_id
  zone          = var.zone
  name          = var.name
  destination   = var.cidr_zone # allow spoke to spoke access through firewall
  action        = "deliver"
  next_hop      = var.next_hop
}

/* todo
resource "ibm_is_vpc_routing_table_route" "all" {
  vpc           = var.vpc_id
  routing_table = var.vpc_routing_table_id
  zone          = var.zone
  name          = "${var.name}-all"
  destination   = "0.0.0.0/0" # allow external access through the firewall
  action        = "deliver"
  next_hop      = var.next_hop
}
*/

/* todo
resource "ibm_is_vpc_routing_table_route" "local" {
  vpc           = var.vpc_id
  routing_table = var.vpc_routing_table_id
  zone          = var.zone
  name          = "${var.name}-local"
  destination   = var.cidr # this subnet
  action        = "delegate_vpc"
  next_hop      = "0.0.0.0"
}
*/

resource "ibm_is_subnet" "zone" {
  tags            = var.tags
  name            = ibm_is_vpc_address_prefix.zone.name
  vpc             = var.vpc_id
  zone            = var.zone
  ipv4_cidr_block = var.cidr
  routing_table   = var.vpc_routing_table_id
}