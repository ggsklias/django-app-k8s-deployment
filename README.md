# djangoarticleapp
 A Django Article App with full automation on DevOps

## Versions used: 
Ansible: 2.18.2
Terraform v1.10.5

This is a "one-button" deployment configured in AWS, Terraform and Ansible.
The ansible playbook:
- Installs prerequisites on the EC2 instances (Amazon Linux 2) to make it work with ansible: 
- Uses buildctl to build the images defined in the Dockerfile - docker-compose.yml
- Uses containerd to load the images
- Installs kubernetes on both instances
- Initiates Kubernetes and installs other prerequisites 
- Worker joins the master node
- Kubernetes manifests applied on the master
-- ConfigMap with the DB details
-- Django Service and Deployment
-- Postgres Service and Deployment
- Returns the IP along with the Node port so that the app can be accessed
There are no costs incurred in AWS as this is using EC2 instances in the free tier.

## How to start the app:
0a) Clone the repo 
0b) get AWS credentials (#link)
export AWS_ACCESS_KEY_ID=XXXX
export AWS_SECRET_ACCESS_KEY=XXXX
export AWS_DEFAULT_REGION=XXX
1) Run python3 provision.py. This creates 2 ec2 instances on AWS and updates the inventory.ini so that ansible knows which host is the master and which is the worker host. 
2) cd provision
3) ansible-playbook -i inventory.ini playbook.yml


# Notes: 
1) The role: A) python_install can be used to install a specific python version on the hosts along with along with pyenv, poetry and python dependencies. 
2) This project focuses on the deployment aspect. The DB secret key is exposed in the config map. In a next iteration it will be added in a vault so that security aspects are addressed.