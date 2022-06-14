output "vpc_id" {
  value = var.vpc_id
}
output "name" {
  value = var.name
}
output "zone" {
  value = var.zone
}
output "cidr" {
  value = var.cidr
}
output "subnet_id" {
  value = ibm_is_subnet.zone.id
}