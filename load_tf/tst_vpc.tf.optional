locals {
  tstprefix = "${local.prefix}-tst"
  tstname   = local.tstprefix
  tstregion = local.region
  tstzone   = "${local.tstregion}-1"
  tstcidr   = "192.168.0.0/24"
  tsttags = [
    "prefix:${local.tstprefix}",
  ]
  tstimage_id = local.globals.image_id
  tstprofile  = local.globals.profile
  tstkeys  = local.globals.keys
}
resource "ibm_is_vpc" "tst" {
  name                      = local.tstprefix
  resource_group = local.resource_group_id
  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "tst" {
  vpc  = ibm_is_vpc.tst.id
  name = local.tstname
  zone = local.tstzone
  cidr = local.tstcidr
}

resource "ibm_is_subnet" "tst" {
  tags            = local.tsttags
  name            = ibm_is_vpc_address_prefix.tst.name
  vpc             = ibm_is_vpc.tst.id
  zone            = local.tstzone
  ipv4_cidr_block = local.tstcidr
}

resource "ibm_is_security_group" "tst" {
  resource_group = local.resource_group_id
  name           = local.tstname
  vpc            = ibm_is_vpc.tst.id
}

resource "ibm_is_security_group_rule" "zone_inbound_all" {
  group     = ibm_is_security_group.tst.id
  direction = "inbound"
}
resource "ibm_is_security_group_rule" "zone_outbound_all" {
  group     = ibm_is_security_group.tst.id
  direction = "outbound"
}

resource "ibm_is_instance" "tst" {
  tags           = local.tsttags
  resource_group = local.resource_group_id
  name           = local.tstname
  image          = local.tstimage_id
  profile        = local.tstprofile
  vpc            = ibm_is_vpc.tst.id
  zone           = ibm_is_subnet.tst.zone
  keys           = local.tstkeys
  user_data      = <<-EOT
    ${local.user_data}
    echo ${local.tstname} > /var/www/html/instance
  EOT

  primary_network_interface {
    subnet          = ibm_is_subnet.tst.id
    security_groups = [ibm_is_security_group.tst.id]
    # allow_ip_spoofing = true
  }
}

resource "ibm_is_floating_ip" "tst" {
  tags           = local.tsttags
  resource_group = local.resource_group_id
  name           = ibm_is_instance.tst.name
  target         = ibm_is_instance.tst.primary_network_interface[0].id
}

output "tst" {
  value = {
    tstf = ibm_is_floating_ip.tst.address
    tstp = ibm_is_instance.tst.primary_network_interface[0].primary_ipv4_address
  }
}