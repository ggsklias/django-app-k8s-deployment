#!/bin/bash
aws s3 cp s3://$AWS_BUCKET_NAME/terraform/terraform.tfstate provision/terraform
aws s3 cp s3://$AWS_BUCKET_NAME/terraform/.terraform.lock.hcl provision/terraform
terraform -chdir=provision/terraform init