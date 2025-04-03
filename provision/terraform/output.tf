
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

output "public_ip_elk" {
  value = flatten(module.elk.public_ip)
}
