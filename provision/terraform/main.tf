provider "aws" {
  region = "eu-central-1"
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