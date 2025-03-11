
variable "ami" {}
variable "size" {
  description = "value of the instance size"
  type = string
}
variable "iam_instance_profile" {
  description = "value of the iam instance profile"
  type = string
}
variable "ssh_key" {
  description = "value of the ssh key"
  type = string
}
variable "subnet_id" {}
variable "security_groups" {
  type = list(any)
}
variable "instance_name" {
    description = "The name tag for the instance"
    type = string
}

resource "aws_instance" "web" {
  ami                  = var.ami # Amazon Linux 2
  instance_type        = var.size
  subnet_id            = var.subnet_id
  key_name             = var.ssh_key
  iam_instance_profile = var.iam_instance_profile

  vpc_security_group_ids = var.security_groups

  tags = {
    Name = var.instance_name
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}