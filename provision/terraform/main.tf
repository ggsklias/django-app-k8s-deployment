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
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}


# 3. Private Subnet (PostgreSQL)
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
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
  iam_instance_profile = "secretsRole"
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
  iam_instance_profile = "secretsRole"
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
  iam_instance_profile = "secretsRole"
  ec2_ssh_key          = "ssh_key"
  subnet_id            = aws_subnet.public1.id
  security_groups      = [aws_security_group.allow_ssh_and_k8s.id]
  instance_name        = "worker"
  instance_count       = 1

}

resource "aws_lb" "app_alb" {
  name               = "k8s-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh_and_k8s.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Environment = var.environment
    Application = "djangoarticleapp"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.listener_mode == "detach" ? "fixed-response" : "forward" # If listener_mode is detach, use fixed-response, otherwise forward

    dynamic "fixed_response" {
      for_each = var.listener_mode == "detach" ? [1] : []
      content {
        content_type = "text/plain"
        message_body = "Service temporarily unavailable"
        status_code  = "503"
      }
    }

    dynamic "forward" {
      for_each = var.listener_mode != "detach" ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.app_tg.arn
        }
      }
    }

  }
}

output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "The DNS name of the application ALB"
}

resource "aws_lb_target_group" "app_tg" {
  name_prefix = "k8s-app-tg-"
  port        = tonumber(var.node_port)
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    protocol            = "HTTP"
    path                = "/healthz/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}


output "public_ip_master" {
  value = flatten(module.masters.public_ip)

}

output "public_ip_worker" {
  value = flatten(module.workers.public_ip)

}

output "public_ip_nginx" {
  value = flatten(module.nginx.public_ip)

}

resource "aws_security_group" "allow_ssh_and_k8s" {
  name        = "allow-ssh-and-k8s"
  description = "Allow SSH and Kubernetes traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    cidr_blocks = ["10.0.1.0/24"] # Only allow traffic from the public subnet
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
  # etcd client url port
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"] # Allow MySQL traffic from the subnet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "tls_private_key" "generated" {
#   algorithm = "RSA"
# }

# resource "local_file" "private_key_pem" {
#   content  = tls_private_key.generated.private_key_pem
#   filename = "MyAWSKey.pem"
# }

# resource "aws_key_pair" "generated" {
#   key_name   = "MyAWSKey"
#   public_key = tls_private_key.generated.public_key_openssh

#   lifecycle {
#     ignore_changes = [key_name]
#   }
# }

# connection {
#   user        = "ec2-user"
#   host        = self.public_ip
#   private_key = tls_private_key.generated.private_key_pem
# }

# provisioner "remote-exec" {
#   inline = [
#     "sudo rm -rf /tmp",
#     "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp",
#     "sudo sh /tmp/assets/setup-web.sh",
#   ]
# }

#   tags = {
#     Name = "worker"
#   }
# }

# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_default_vpc.main.id
# }

# Creating a IAM role through terraform

# # Create the IAM role for EC2
# resource "aws_iam_role" "secrets" {
#   name = "secrets"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect    = "Allow",
#       Principal = { Service = "ec2.amazonaws.com" },
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

# # Attach the AWS managed SecretsManagerReadWrite policy
# resource "aws_iam_role_policy_attachment" "secrets_policy_attachment" {
#   role       = aws_iam_role.secrets.name
#   policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
# }

# # Create an instance profile that uses this role
# resource "aws_iam_instance_profile" "secrets_profile" {
#   name = "secrets"
#   role = aws_iam_role.secrets.name
# }