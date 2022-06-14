# transit zone
#

locals {
  # todo - how can this primary always be the next hop?  There is a secondary address as well.
  next_hop = ibm_is_lb.zone.private_ips[0]
  cidr_available0 = cidrsubnet(var.cidr, 2, 0)
  cidr_available1 = cidrsubnet(var.cidr, 2, 1)
  cidr_available2 = cidrsubnet(var.cidr, 2, 2)
  cidr_firewall = cidrsubnet(var.cidr, 2, 3)
}

# Prefix for the entire zone not just the VPC
resource "ibm_is_vpc_address_prefix" "zone" {
  vpc  = var.vpc_id
  name = var.name
  zone = var.zone
  cidr = var.cidr_zone
}

resource "ibm_is_public_gateway" "zone" {
  vpc  = var.vpc_id
  name = var.name
  zone = var.zone
}

resource "ibm_is_subnet" "zone" {
  tags                      = var.tags
  name            = ibm_is_vpc_address_prefix.zone.name
  vpc             = var.vpc_id
  zone            = var.zone
  ipv4_cidr_block = local.cidr_firewall
  public_gateway  = ibm_is_public_gateway.zone.id
}

resource "ibm_is_subnet" "available0" {
  tags                      = var.tags
  name            = "${ibm_is_vpc_address_prefix.zone.name}-0"
  vpc             = var.vpc_id
  zone            = var.zone
  ipv4_cidr_block = local.cidr_available0
}

resource "ibm_is_security_group" "zone" {
  resource_group = var.resource_group_id
  name           = var.name
  vpc            = var.vpc_id
}

resource "ibm_is_security_group_rule" "zone_inbound_all" {
  group     = ibm_is_security_group.zone.id
  direction = "inbound"
}
resource "ibm_is_security_group_rule" "zone_outbound_all" {
  group     = ibm_is_security_group.zone.id
  direction = "outbound"
}

resource "ibm_is_lb" "zone" {
  route_mode = true
  name    = var.name
  subnets = [ibm_is_subnet.zone.id]
  profile = "network-fixed"
  type    = "private"
}
resource "ibm_is_lb_listener" "zone" {
  lb           = ibm_is_lb.zone.id
  default_pool = ibm_is_lb_pool.zone.id
  protocol     = "tcp"
  #port_min         = 1
  #port_max         = 65535
}

resource "ibm_is_lb_pool" "zone" {
  name                     = var.name
  lb                       = ibm_is_lb.zone.id
  algorithm                = "round_robin"
  protocol                 = "tcp"
  session_persistence_type = "source_ip"
  health_delay             = 60
  health_retries           = 5
  health_timeout           = 30
  health_type              = "http"
  health_monitor_url       = "/"
  #health_monitor_port    = 80
}
resource "ibm_is_lb_pool_member" "zone" {
  for_each  = ibm_is_instance.zone
  lb        = ibm_is_lb.zone.id
  pool      = element(split("/", ibm_is_lb_pool.zone.id), 1)
  port      = 80
  target_id = each.value.id
  #target_address = each.value.primary_network_interface[0].primary_ipv4_address
  #weight = 50
}

resource "ibm_is_instance" "zone" {
  for_each = {
    0 = 0
    # 1 = 1 # demonstrate multiple instances
  }
  tags                      = var.tags
  resource_group = var.resource_group_id
  name           = "${var.name}-${each.value}"
  image          = var.image_id
  profile        = var.profile
  vpc            = var.vpc_id
  zone           = ibm_is_subnet.zone.zone
  keys           = var.keys
  user_data      = <<-EOT
    ${var.user_data}
    echo ${var.name} > /var/www/html/instance
    sysctl -w net.ipv4.ip_forward=1
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf 
  EOT

  primary_network_interface {
    subnet          = ibm_is_subnet.zone.id
    security_groups = [ibm_is_security_group.zone.id]
    allow_ip_spoofing = true
  }
}

resource "ibm_is_vpc_routing_table_route" "zone" {
  vpc  = var.vpc_id
  routing_table = var.vpc_routing_table_id
  zone          = var.zone
  name = var.name
  destination   = var.cidr_zone
  action        = "deliver"
  next_hop      = local.next_hop
}

resource "ibm_is_floating_ip" "zone" {
  for_each = ibm_is_instance.zone
  tags                      = var.tags
  resource_group = var.resource_group_id
  name           = each.value.name
  target         = each.value.primary_network_interface[0].id
}