
variable "availability_zones" {
  description = "AZs in this region to use"
  type = list(string)
  }

variable "vpc_cidr" {
  }

variable "public_cidrs" {
  type    = list(string)
  }

variable "private_cidrs" {
  type    = list(string)
}
