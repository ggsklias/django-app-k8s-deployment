variable "node_port" {
  description = "The Kubernetes NodePort on which the application is exposed"
  type        = number
  default = 30000
}

variable "environment" {
  description = "The environment in which the infrastructure is deployed"
  type        = string
  default     = "staging"
}
