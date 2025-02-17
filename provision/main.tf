provider "aws" {
  region = "eu-central-1"
}

# resource "aws_key_pair" "ssh_key" {
#   key_name   = ""                # Specify the key pair name
#   public_key = file("public-key.pub")  # Reference the public key file (you should have this after running ssh-keygen)
# }


# 1. VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "custom-vpc"
  }
}

# 2. Public Subnet (Web Server)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# 3. Private Subnet (PostgreSQL)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1a"
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
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_instance" "master" {
  ami           = "ami-0764af88874b6b852" # Amazon Linux 2
  #ami           = "ami-099da3ad959447ffa" # Amazon Linux 2023 AMI, which supports dnf
  instance_type = "t2.micro"
  key_name      = "ssh_key" # Replace with your SSH key pair name
  # This is only for defaul
  # security_groups = ["allow-ssh-and-k8s"]
  vpc_security_group_ids = [aws_security_group.allow_ssh_and_k8s.id]
  subnet_id = aws_subnet.public.id

  tags = {
    Name = "master"
  }
}

resource "aws_instance" "worker" {
  ami           = "ami-0764af88874b6b852" # Amazon Linux 2
  # ami           = "ami-099da3ad959447ffa" # Amazon Linux 2023 AMI, which supports dnf
  instance_type = "t2.micro"
  key_name      = "ssh_key" # Replace with your SSH key pair name
  # This is only for default vpcs apparently
  # security_groups = ["allow-ssh-and-k8s"]
  vpc_security_group_ids = [aws_security_group.allow_ssh_and_k8s.id]
  subnet_id = aws_subnet.public.id
  
  tags = {
    Name = "worker"
  }
}

# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_default_vpc.main.id
# }

resource "aws_security_group" "allow_ssh_and_k8s" {
  name        = "allow-ssh-and-k8s"
  description = "Allow SSH and Kubernetes traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port   = -1
  #   to_port     = -1
  #   protocol    = "icmp"
  # }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8285
    to_port     = 8285
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]  # Only allow traffic from the public subnet
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]  # Allow MySQL traffic from the subnet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# output "master_private_ip" {
#   value = aws_instance.master.private_ip
# }

# output "worker_private_ip" {
#   value = aws_instance.worker.private_ip
# }

output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ip" {
  value = aws_instance.worker.public_ip
}