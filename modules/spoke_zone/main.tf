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
  destination   = var.cidr_zone
  # destination   = "0.0.0.0/0" # allow external access
  action        = "deliver"
  next_hop      = var.next_hop
}

resource "ibm_is_subnet" "zone" {
  tags            = var.tags
  name            = ibm_is_vpc_address_prefix.zone.name
  vpc             = var.vpc_id
  zone            = var.zone
  ipv4_cidr_block = var.cidr
  routing_table   = var.vpc_routing_table_id
}