variable "rds_subnet1" {}
variable "rds_subnet2" {}
variable "db_instance" {}
variable "vpc_id" {}
variable "security_groups" {}
variable "username" {
  type = string
}

variable "password" {
  type = string
}
