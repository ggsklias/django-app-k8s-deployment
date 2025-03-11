terraform {
  required_version = "~> 1.10.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.5"
    }
    random = {
      source = "hashicorp/random"
      version = "3.5.1"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }
    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}