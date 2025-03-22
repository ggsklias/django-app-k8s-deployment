output "public_ip" {
  value = aws_instance.locust[*].public_ip
}