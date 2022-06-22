variable "tags" {}
variable "vpc_id" {}
variable "vpc_default_routing_table" {}
variable "resource_group_id" {}
variable "image_id" {}
variable "profile" {}
variable "keys" {}
variable "firewall_lb" {}
variable "number_of_firewalls_per_zone" {}
variable "user_data" {}
variable "use_routing" {}

# see common.tf: local.cidr_transit_vpc
variable "name" {}
variable "zone" {}
variable "cidr_zone" {}
variable "cidr" {}
