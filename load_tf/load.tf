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
  echo v1 todo
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
  spokes_zones = { for spoke_key, spoke in local.spokes : spoke_key => {
    vpc_id          = spoke.vpc_id
    security_groups = [ibm_is_security_group.spoke_all[spoke_key].id]
    name            = "${local.name}-${spoke_key}"
    zones = { for zone_key, zone in spoke.zones : zone_key => {
      spoke_key       = spoke_key                                       # repeated
      vpc_id          = spoke.vpc_id                                    # repeated
      security_groups = [ibm_is_security_group.spoke_all[spoke_key].id] # repeated

      name      = "${local.name}-${spoke_key}-${zone.zone}"
      zone      = zone.zone
      subnet_id = zone.subnet_id
      zone_key  = zone_key
      }
    }
  } }
  # one instance in each zone
  instances = flatten([for spoke_key, spoke in local.spokes_zones : [for zone_key, zone in spoke.zones : zone]])
}
resource "ibm_is_instance" "zone" {
  for_each       = { for index, value in local.instances : index => value }
  tags           = local.tags
  resource_group = local.resource_group_id
  name           = each.value.name
  image          = local.globals.image_id
  profile        = local.globals.profile
  vpc            = each.value.vpc_id
  zone           = each.value.zone
  keys           = local.globals.keys
  user_data      = <<-EOT
    ${local.user_data}
    echo ${each.value.name} > /var/www/html/instance
  EOT

  primary_network_interface {
    subnet          = each.value.subnet_id
    security_groups = each.value.security_groups
  }
}
resource "ibm_is_floating_ip" "zone" {
  for_each       = ibm_is_instance.zone
  tags           = local.tags
  resource_group = local.resource_group_id
  name           = each.value.name
  target         = each.value.primary_network_interface[0].id
}

output "instances" {
  value = { for key, value in ibm_is_instance.zone : key => {
    primary_ipv4_address = value.primary_network_interface[0].primary_ipv4_address
    name                 = value.name
    floating_ip_address  = ibm_is_floating_ip.zone[key].address
  } }
}

output "transit_zones" {
  value = local.transit_zones
}

# one more on spoke 1 no fip:
resource "ibm_is_instance" "extra" {
  # todo just spoke 1 or all spokes?
  #for_each       = { for index, value in [local.spokes_zones[1].zones[0]] : index => value }
  for_each       = { for index, value in local.instances : index => value }
  tags           = local.tags
  resource_group = local.resource_group_id
  name           = "${each.value.name}-extra"
  image          = local.globals.image_id
  profile        = local.globals.profile
  vpc            = each.value.vpc_id
  zone           = each.value.zone
  keys           = local.globals.keys
  user_data      = <<-EOT
    ${local.user_data}
    echo ${each.value.name} > /var/www/html/instance
  EOT

  primary_network_interface {
    subnet          = each.value.subnet_id
    security_groups = each.value.security_groups
  }
}

output "extra-instances" {
  value = { for key, value in ibm_is_instance.extra : key => {
    primary_ipv4_address = value.primary_network_interface[0].primary_ipv4_address
    name                 = value.name
  } }
}
