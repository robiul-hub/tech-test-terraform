
# Creating VPC

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "My-VPC" 
  }
}

# Creating IGW to route out to the public internet

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id 

  tags = {
    Name = "My-IGW" 
  }
}


# Create Public Route Table

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id 
  }

  tags = {
    Name = "My-Public-RT" 
  }
}

# Creatong Private Route Table

resource "aws_default_route_table" "private_route" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = {
    Name = "My-Private-RT"
  }
}

# Creating 2 Public Subnets

resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_cidrs) 
  cidr_block              = var.public_cidrs[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]

  tags = {
    Name = "Public-Subnet ${count.index + 1}"
  }
}

# Creating 2 Private Subnets

resource "aws_subnet" "private_subnet" {
  count             = length(var.private_cidrs) 
  cidr_block        = var.private_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "Private-Subnet ${count.index + 1}"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_subnet_assoc" {
  count          = length(var.public_cidrs) 
  route_table_id = aws_route_table.public_route.id
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  depends_on     = [aws_route_table.public_route, aws_subnet.public_subnet]
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_subnet_assoc" {
  count          = length(var.private_cidrs) 
  route_table_id = aws_default_route_table.private_route.id
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]
  depends_on     = [aws_default_route_table.private_route, aws_subnet.private_subnet]
}

resource "aws_security_group" "web-sg" {
  name        = "allow_WebTraffic"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-DMZ"
  }
}