variable "node_port" {
  description = "The Kubernetes NodePort on which the application is exposed"
  type        = string
  default     = "30000"
}

variable "environment" {
  description = "The environment in which the infrastructure is deployed"
  type        = string
  default     = "staging"
}

variable "listener_mode" {
  description = "Listener mode: 'detach' for fixed-response, 'forward' for normal operation"
  type        = string
  default     = "forward"
}

variable "target_group_arn" {
  description = "The ARN of the target group for normal operation"
  type        = string
  default     = ""
}