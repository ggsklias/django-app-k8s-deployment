output "public_ip" {
  value = aws_instance.worker[*].public_ip
}