# djangoarticleapp - Version 1
 A Django Article App with fully automated deployment on AWS with Terraform and Ansible.

## Overview
This is a "one-button" deployment configured in AWS, Terraform and Ansible.
The ansible playbook:
- Installs prerequisites on the EC2 instances (Amazon Linux 2) to enable ansible 2.18.2
- Installs djangoarticleapp on the worker host
- Uses buildctl to build the images defined in the Dockerfile - docker-compose.yml
- Uses containerd to load the images
- Installs kubernetes on both instances
- Initiates Kubernetes on the master
- Worker joins the master node
- Kubernetes manifests applied on the master
-- ConfigMap with the DB details
-- Django Service and Deployment
-- Postgres Service and Deployment
- Returns the IP along with the Node port so that the app can be accessed

## How to start the app:
1) Clone the repo 
2) [Get AWS credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
export AWS_ACCESS_KEY_ID=XXXX
export AWS_SECRET_ACCESS_KEY=XXXX
3) Store the private key in the provision folder and update inventory.ini accordingly with the right path. 
4) cd provision
5) Run python3 provision.py. This creates 2 ec2 instances on AWS and updates the inventory.ini so that ansible knows which host is the master and which is the worker host. 
6) ansible-playbook -i inventory.ini playbook.yml
7) Wait for the playbook to complete and connect to the app using the link provided by the ansible playbook

## Tear down:
8) terraform destroy -auto-approve


# Notes: 
- This project focuses on the deployment aspect. The DB secret key is exposed in the config map. In a next iteration it will be added in a vault so that security aspects are addressed.
- The deployment is using EC2 instances in the free tier so that no costs are incurred.  