
resource "aws_db_instance" "my-test-sql" {
  instance_class          = var.db_instance
  engine                  = "mysql"
  engine_version          = "5.7"
  multi_az                = true
  storage_type            = "gp2"
  allocated_storage       = 20
  name                    = "MyRDS"
  username                = var.username
  password                = var.password
  apply_immediately       = "true"
  db_subnet_group_name    = aws_db_subnet_group.my-rds-db-subnet.name
  vpc_security_group_ids  = [aws_security_group.DB-sg.id] 
}

resource "aws_db_subnet_group" "my-rds-db-subnet" {
  name       = "my-rds-db-subnet"
  subnet_ids = [var.rds_subnet1, var.rds_subnet2] 

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_security_group" "DB-sg" {
  name        = "Database SG"
  description = "Allow  traffic from public subnet instances"
  vpc_id = var.vpc_id 

  ingress {
    description = "MySQL DB access port"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups   = [var.security_groups] 
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups   = [var.security_groups] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DataBase-SG"
  }
}
