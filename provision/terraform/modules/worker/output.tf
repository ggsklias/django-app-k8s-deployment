output "public_ip" {
  value = aws_instance.worker[*].public_ip
}

output "instance_ids" {
  description = "List of worker instance IDs"
  value       = aws_instance.worker[*].id
}
