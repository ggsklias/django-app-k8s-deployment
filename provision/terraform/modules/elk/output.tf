output "public_ip" {
  value = aws_instance.elk[*].public_ip
}