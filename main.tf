provider "aws" {
  region     = "us-east-2"
  access_key = "AKIAWVGHSADVD7MDMBSE"
  secret_key = "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"
}

module "vpc" {
  source             = "./vpc"
  vpc_cidr           = "10.0.0.0/16"
  public_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs      = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones = ["us-east-2a", "us-east-2b"]
}

module "alb" {
  source = "./alb"
  vpc_id = module.vpc.aws_vpc_id
  subnet1        = module.vpc.subnet1
  subnet2        = module.vpc.subnet2
  security_group = module.vpc.security1_group
}

module "auto_scaling" {
  source           = "./asg"
  vpc_id           = module.vpc.aws_vpc_id
  subnet1          = module.vpc.subnet1
  subnet2          = module.vpc.subnet2
  security_group   = module.vpc.security1_group
  target_group_arn = module.alb.alb_target_group_arn
  min_size         = 2
  max_size         = 4
  desired_capacity = 2
  image_id         = "ami-0a0ad6b70e61be944" //Used Amazon Linux 2
  instance_type    = "t2.micro"
}
/*
module "rds" {
  source          = "./rds"
  db_instance     = "db.t2.micro"
  rds_subnet1     = module.vpc.private_subnet1
  rds_subnet2     = module.vpc.private_subnet2
  vpc_id          = module.vpc.aws_vpc_id
  security_groups = module.vpc.security1_group
}*/

