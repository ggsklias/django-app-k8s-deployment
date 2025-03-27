#!/bin/bash
aws s3 cp s3://$AWS_BUCKET_NAME/terraform/terraform.tfstate .
aws s3 cp s3://$AWS_BUCKET_NAME/terraform/.terraform.lock.hcl .
terraform -chdir=provision/terraform init