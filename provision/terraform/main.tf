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
  instance_name        = "nginx"
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

output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "The DNS name of the application ALB"
}

resource "aws_lb_target_group" "app_tg" {
  name_prefix = "k8tg-"
  port        = tonumber(var.node_port)
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    protocol            = "HTTP"
    path                = "/healthz"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }

}

locals {
  # Convert the tuple to a map with indices as keys.
  worker_instance_map = { for idx, instance_id in module.workers.instance_ids : idx => instance_id }
}

resource "aws_lb_target_group_attachment" "worker_attachments" {
  for_each         = local.worker_instance_map
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = each.value
  port             = var.node_port
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.app_tg]

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.app_tg.arn
        weight = 100
      }
    }
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

output "public_ip_locust" {
  value = flatten(module.locust.public_ip)
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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
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
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 123
    to_port     = 123
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
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9093
    to_port     = 9093
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

module "locust" {
  source = "./modules/locust"

  ami                  = "ami-0764af88874b6b852"
  size                 = "t2.micro"
  iam_instance_profile = "secretsRole"
  ec2_ssh_key          = "ssh_key"
  subnet_id            = aws_subnet.public1.id
  security_groups      = [aws_security_group.allow_connections_for_locust.id]
  instance_name        = "locust"
  instance_count       = 1

}

resource "aws_security_group" "allow_connections_for_locust" {
  name        = "allow-connections-for-locust"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
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

  ingress {
    from_port   = 30089
    to_port     = 30089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
}



# provider "tls" {}

# resource "aws_lb_listener" "app_listener" {
#   load_balancer_arn = aws_lb.app_alb.arn
#   port              = 80
#   protocol          = "HTTP"
#   depends_on        = [aws_lb_target_group.app_tg]

#   default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301" # Use 301 for permanent redirection; 302 for temporary
#     }
#   }
# }

# resource "aws_lb_listener" "https_listener" {
#   load_balancer_arn = aws_lb.app_alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate.imported_cert.arn
#   depends_on        = [aws_lb_target_group.app_tg]

#   default_action {
#     type = "forward"
#     forward {
#       target_group {
#         arn    = aws_lb_target_group.app_tg.arn
#         weight = 100
#       }
#     }
#   }
# }


# resource "aws_acm_certificate" "imported_cert" {
#   certificate_body  = tls_self_signed_cert.self_signed_cert.cert_pem
#   private_key       = tls_private_key.self_signed.private_key_pem
#   certificate_chain = "" # Self-signed, so no chain

#   tags = {
#     Environment = var.environment
#   }
# }


# resource "tls_self_signed_cert" "self_signed_cert" {
#   private_key_pem = tls_private_key.self_signed.private_key_pem

#   subject {
#     # Using the ALB's DNS name as the common name.
#     common_name = aws_lb.app_alb.dns_name
#   }

#   validity_period_hours = 8760 # 1 year
#   early_renewal_hours   = 168  # 1 week before expiry

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#   ]
# }


# resource "tls_private_key" "self_signed" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

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