data "terraform_remote_state" "pattern" {
  backend = "local"

  config = {
    path = "../terraform.tfstate"
  }
}

locals {
  spokes            = data.terraform_remote_state.pattern.outputs.spokes
  transit_zones     = data.terraform_remote_state.pattern.outputs.transit_zones
  globals           = data.terraform_remote_state.pattern.outputs.globals
  resource_group_id = local.globals.resource_group_id
  region            = local.globals.region

  prefix    = "${local.globals.prefix}-load"
  name      = local.prefix
  user_data = <<-EOT
  #!/bin/bash
  set -x
  export DEBIAN_FRONTEND=noninteractive
  apt -qq -y update < /dev/null
  apt -qq -y install net-tools nginx npm < /dev/null
  EOT
  tags = [
    "prefix:${local.prefix}",
    # lower(replace("dir:${abspath(path.root)}", "/", "_")),
  ]
}

resource "ibm_is_security_group" "spoke_all" {
  for_each       = local.spokes
  resource_group = local.resource_group_id
  name           = local.name
  vpc            = each.value.vpc_id
}

resource "ibm_is_security_group_rule" "spoke_inbound_all" {
  for_each  = ibm_is_security_group.spoke_all
  group     = each.value.id
  direction = "inbound"
}
resource "ibm_is_security_group_rule" "spoke_outbound_all" {
  for_each  = ibm_is_security_group.spoke_all
  group     = each.value.id
  direction = "outbound"
}

locals {
  # capture all the instance specific parameters:
  instances = flatten([for spoke_key, spoke in local.spokes :
    [for zone_key, zone in spoke.zones : {
      spoke_key       = spoke_key                                       # repeated
      vpc_id          = spoke.vpc_id                                    # repeated
      security_groups = [ibm_is_security_group.spoke_all[spoke_key].id] # repeated
      name            = "${local.name}-${spoke_key}-${zone.zone}"
      zone            = zone.zone
      subnet_id       = zone.subnet_id
      zone_key        = zone_key
      }
    ]
  ])
}
resource "ibm_is_instance" "private" {
  for_each       = { for index, value in local.instances : index => value }
  tags           = local.tags
  resource_group = local.resource_group_id
  name           = "${each.value.name}-private"
  image          = local.globals.image_id
  profile        = local.globals.profile
  vpc            = each.value.vpc_id
  zone           = each.value.zone
  keys           = local.globals.keys
  user_data      = <<-EOT
    ${local.user_data}
    echo ${each.value.name}-private > /var/www/html/instance
  EOT

  primary_network_interface {
    subnet          = each.value.subnet_id
    security_groups = each.value.security_groups
  }
}

#----- transit bastion instance ----------------------------
resource "ibm_is_security_group" "transit_bastion_all" {
  resource_group = local.resource_group_id
  name           = "transit-bastion"
  vpc            = local.transit_zones[0].vpc_id
}

resource "ibm_is_security_group_rule" "transit_inbound_all" {
  group     = ibm_is_security_group.transit_bastion_all.id
  direction = "inbound"
}
resource "ibm_is_security_group_rule" "transit_outbound_all" {
  group     = ibm_is_security_group.transit_bastion_all.id
  direction = "outbound"
}

resource "ibm_is_instance" "transit" {
  for_each       = local.transit_zones
  tags           = local.tags
  resource_group = local.resource_group_id
  name           = "${each.value.name}-bastion"
  image          = local.globals.image_id
  profile        = local.globals.profile
  vpc            = each.value.vpc_id
  zone           = each.value.zone
  keys           = local.globals.keys
  user_data      = <<-EOT
    ${local.user_data}
    echo ${each.value.name}-bastion > /var/www/html/instance
  EOT

  primary_network_interface {
    subnet          = each.value.subnet_bastion_id
    security_groups = [ibm_is_security_group.transit_bastion_all.id]
  }
}

resource "ibm_is_floating_ip" "transit" {
  for_each       = ibm_is_instance.transit
  tags           = local.tags
  resource_group = local.resource_group_id
  name           = each.value.name
  target         = each.value.primary_network_interface[0].id
}

#----
output "spoke_instances" {
  value = [for i, instance in local.instances : {
    primary_ipv4_address = ibm_is_instance.private[i].primary_network_interface[0].primary_ipv4_address
    zone_key             = instance.zone_key
    zone                 = instance.zone
    spoke_key            = instance.spoke_key
    name                 = instance.name
    jump_floating_ip     = ibm_is_floating_ip.transit[instance.zone_key].address
    name                 = instance.name
    ssh                  = "ssh -J root@${ibm_is_floating_ip.transit[instance.zone_key].address} root@${ibm_is_instance.private[i].primary_network_interface[0].primary_ipv4_address}"
  }]
}
