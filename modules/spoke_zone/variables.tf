variable "tags" {}
variable "vpc_id" {}
variable "vpc_default_routing_table" {}
variable "use_routing" {}
variable "resource_group_id" {}
variable "image_id" {}
variable "profile" {}
variable "keys" {}
variable "user_data" {}

variable "cidr_zone" {}
variable "cidr_transit" {}
variable "next_hop" {}

# see common.tf: local.cidr_transit_vpc
variable "name" {}
variable "zone" {}
variable "cidr" {}
