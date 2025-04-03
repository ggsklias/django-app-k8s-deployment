provider "aws" {
  region = "eu-central-1"
}

# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "custom-vpc"
  }
}

# 2. Public Subnet (Web Server)
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}


# 3. Private Subnet (PostgreSQL)
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  #availability_zone = "eu-central-1a"
  tags = {
    Name = "private-subnet"
  }
}

# 4. Internet Gateway for Public Subnet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "custom-internet-gateway"
  }
}

# 5. Route Table for Public Subnet (Allows Internet Access)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# 6. Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

module "masters" {
  source = "./modules/master"

  ami                  = "ami-0764af88874b6b852"
  size                 = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ci_infrastructure_access.name
  ec2_ssh_key          = "ssh_key"
  subnet_id            = aws_subnet.public1.id
  security_groups      = [aws_security_group.allow_ssh_and_k8s.id]
  instance_name        = "master"
  instance_count       = 3

}

module "workers" {
  source = "./modules/worker"

  ami                  = "ami-0764af88874b6b852"
  size                 = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ci_infrastructure_access.name
  ec2_ssh_key          = "ssh_key"
  subnet_id            = aws_subnet.public1.id
  security_groups      = [aws_security_group.allow_ssh_and_k8s.id]
  instance_name        = "worker"
  instance_count       = 2

}

module "nginx" {
  source = "./modules/nginx"

  ami                  = "ami-0764af88874b6b852"
  size                 = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ci_infrastructure_access.name
  ec2_ssh_key          = "ssh_key"
  subnet_id            = aws_subnet.public1.id
  security_groups      = [aws_security_group.allow_ssh_and_k8s.id]
  instance_name        = "nginx"
  instance_count       = 1

}

module "locust" {
  source = "./modules/locust"

  ami                  = "ami-0764af88874b6b852"
  size                 = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ci_infrastructure_access.name
  ec2_ssh_key          = "ssh_key"
  subnet_id            = aws_subnet.public1.id
  security_groups      = [aws_security_group.allow_ssh_and_k8s.id]
  instance_name        = "locust"
  instance_count       = 1

}

module "elk" {
  source = "./modules/elk"

  ami                  = "ami-0764af88874b6b852"
  size                 = "t2.medium"
  iam_instance_profile = aws_iam_instance_profile.ci_infrastructure_access.name
  ec2_ssh_key          = "ssh_key"
  subnet_id            = aws_subnet.public1.id
  security_groups      = [aws_security_group.allow_ssh_and_k8s.id]
  instance_name        = "elk"
  instance_count       = 4

}