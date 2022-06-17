variable "tags" {}
variable "vpc_id" {}
variable "resource_group_id" {}
variable "image_id" {}
variable "profile" {}
variable "keys" {}
variable "firewall_lb" {}
variable "firewall_replicas" {}
variable "user_data" {}

# see common.tf: local.cidr_transit_vpc
variable "name" {}
variable "zone" {}
variable "cidr_zone" {}
variable "cidr" {}