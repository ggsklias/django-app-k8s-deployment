variable "node_port" {
  description = "The Kubernetes NodePort on which the application is exposed"
  type        = string
  default     = "31131"
}

variable "environment" {
  description = "The environment in which the infrastructure is deployed"
  type        = string
  default     = "staging"
}

variable "target_group_arn" {
  description = "The ARN of the target group for normal operation"
  type        = string
  default     = ""
}
