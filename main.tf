resource "aws_vpc" "vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  tags = {
   Name = "VPC-${var.module_name}"
 }
}


resource "aws_internet_gateway" "internet_gateway" {
 vpc_id = aws_vpc.vpc.id
 tags = {
   Name = "InternetGateway-${var.module_name}"
 }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_subnet" {
    count = 2
    vpc_id            = aws_vpc.vpc.id
    cidr_block = "10.20.${10+count.index}.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = true
    
    tags = {
        Name = "PublicSubnet-${var.module_name}"
    }
}

resource "aws_subnet" "private_subnet" {
    count = 2
    vpc_id            = aws_vpc.vpc.id
    cidr_block = "10.20.${20+count.index}.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = false
    
    tags = {
        Name = "PrivateSubnet-${var.module_name}}"
    }
}

resource "aws_security_group" "server_security_group" {
  name        = "${var.module_name}-SecurityGroup"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    to_port     = "0"
  }

  tags = {
    "Name" = "${var.module_name}-SecurityGroup"
  }
}

module "ec2_instance" {
  source = "../Lab-03-1103-EC2Module"

  region = var.region
  ami = "ami-0aaa5410833273cfe"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private_subnet[0].id
  instance_name = var.module_name
  security_group_id = aws_security_group.server_security_group.id
}

module "rds_instance" {
  source = "../Lab-03-1103-RDSModule"

  region = var.region
  security_group_id = aws_security_group.server_security_group.id
  db_name = "rds"
  identifier = "rds-instance-main"
  engine = "postgres"
  engine_version = "12"
  instance_class = "db.t2.micro"
  storage_size = 5
  username = "iacTestUser"
  password = "userPassTest"
  subnet_group_name_list = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]
}

module "sqs_queue" {
  source = "../Lab-03-1103-SQSModule"

  region = var.region
  queue_name = var.module_name
}