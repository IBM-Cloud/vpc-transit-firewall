# variables - see template.local.env for the required variables

variable "prefix" {
  description = "resources created will be named: $${prefix}vpc-pubpriv, vpc name will be $${prefix} or will be defined by vpc_name"
  default     = "reglb"
}

variable "resource_group_name" {
  description = "Resource group that will contain all the resources created by the script."
}

variable "ssh_key_name" {
  description = "SSH keys are needed to connect to virtual instances. https://cloud.ibm.com/docs/vpc?topic=vpc-getting-started"
}


variable "region" {
  description = "Availability zone that will have the resources deployed to.  To obtain a list of availability zones you can run the ibmcloud cli: ibmcloud is regions."
  default     = "us-south"
}

variable "zones_cloud" {
  description = "number of zones in the cloud, 1..3"
  default     = 1
}

variable "spokes" {
  description = "number of spokes in the cloud, 0..n-1"
  default     = 2
}

variable "firewall_lb" {
  description = "is there a firewall load balancer?"
  default     = true
}

variable "firewall_replicas" {
  description = "number of firewalls in each zone, 1 is good for initial testing, 2 is more typical"
  default     = 1
}

variable "spoke_routing" {
  description = <<-EOT
  Is there spoke routing?  There must be for the firewalls to be engaged. Useful for testing"
  EOT
  default     = true
}
