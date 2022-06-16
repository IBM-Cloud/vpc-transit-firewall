locals {
  tags = [
    "prefix:${var.prefix}",
    # lower(replace("dir:${abspath(path.root)}", "/", "_")),
  ]
  # onprem
  cidr_onprem = "10.0.0.0/14"
  zone_onprem = "${var.region}-1"

  # cloud configuration
  cidr_cloud  = "10.8.0.0/14"
  zones_cloud = 2
  cidr_cloud_zones = { for zone in range(var.zones_cloud) : zone => {
    zone = "${var.region}-${zone + 1}" # us-south-1, us-south-2, ...
    cidr = cidrsubnet(local.cidr_cloud, 2, zone),
  } }
  # transit vpc cidr
  cidr_transit_vpc = { for zone in range(var.zones_cloud) : zone => {
    name      = "${var.prefix}-transit-${zone + 1}"
    zone      = "${var.region}-${zone + 1}"
    cidr      = cidrsubnet(local.cidr_cloud_zones[zone].cidr, 8, 0) # cidr for entire zone
    cidr_zone = local.cidr_cloud_zones[zone].cidr                   # cidr for entire zone
  } }

  # spokes, range 0..n-1
  spokes = var.spokes
  # spoke vpc 
  cidr_spoke_vpc = { for spoke in range(var.spokes) : spoke => {
    name = "${var.prefix}-spoke-${spoke}"
    zones = { for zone in range(var.zones_cloud) : zone => {
      name      = "${var.prefix}-spoke-${spoke}-${var.region}-${zone + 1}"
      zone      = "${var.region}-${zone + 1}"
      cidr      = cidrsubnet(local.cidr_cloud_zones[zone].cidr, 8, spoke + 1)
      cidr_zone = local.cidr_cloud_zones[zone].cidr # cidr for entire zone
  } } } }

  # misc
  cloud_image_name = "ibm-ubuntu-20-04-3-minimal-amd64-2"
  profile          = "cx2-2x4"
}

data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

data "ibm_is_image" "os" {
  name = local.cloud_image_name
}