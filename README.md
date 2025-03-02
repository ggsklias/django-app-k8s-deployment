# djangoarticleapp - Version 1
 A Django Article App with fully automated deployment on AWS with Gitlab CI/CD, Terraform and Ansible.

# Deployment Process Description

This document outlines the complete process for provisioning infrastructure, setting up the Kubernetes cluster, deploying the Django application, and exposing the application.

---

### 1. Infrastructure Provisioning

1. **Terraform:**
   - **Objective:** Create the necessary cloud infrastructure.
   - **Actions:**
     - Spin up two EC2 instances (one for the master and one for the worker).
     - Provision the VPC, security groups, subnets, and SSH permissions.

2. **Ansible – Prerequisites Installation:**
   - **Objective:** Prepare the newly provisioned EC2 instances for further configuration.
   - **Actions:**
     - Install required packages and dependencies on the Amazon Linux 2 instances to support the automation and subsequent application deployments (using Ansible 2.18.2).

---

### 2. Application Deployment Setup

1. **Django Article App Installation:**
   - **Objective:** Deploy the core Django application.
   - **Actions:**
     - Configure the worker instance to host and run the Django article app.

2. **Docker Image Build & Registry Integration:**
   - **Objective:** Automate container image building and storage.
   - **Actions:**
     - Configure GitLab CI to build the Docker image for the Django article app whenever code changes occur.
     - Push the built image to the GitLab Container Registry (tagged, for example, with the commit SHA).

3. **Container Deployment:**
   - **Objective:** Run the containerized application on the EC2 instance.
   - **Actions:**
     - Use containerd on the EC2 instance to pull the Docker image from the GitLab Container Registry.
     - Load and run the container without manual intervention.

---

### 3. Kubernetes Cluster Setup

1. **Kubernetes Installation (via Ansible):**
   - **Objective:** Set up a container orchestration platform.
   - **Actions:**
     - Install Kubernetes components (e.g., kubeadm, kubectl, kubelet) on both the master and worker instances.

2. **Cluster Initialization & Node Joining:**
   - **Objective:** Form a functional Kubernetes cluster.
   - **Actions:**
     - Initialize the Kubernetes master node.
     - Join the worker node to the master node to complete the cluster formation.

3. **Applying Kubernetes Manifests:**
   - **Objective:** Deploy application components onto the Kubernetes cluster.
   - **Actions:**
     - Use Ansible to apply Kubernetes manifests on the master.
     - Manifests include:
       - A ConfigMap with database configuration details.
       - A Deployment and Service for the Django application (referencing the GitLab Container Registry image).
       - A Deployment and Service for the PostgreSQL database.

---

### 4. Application Access

1. **Objective:**
   - Provide end users with the necessary access details.
2. **Actions:**
   - Return the public IP address and NodePort, enabling users to access the running Django application.



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


## Notes: 
- This project focuses on the deployment aspect. The DB secret key is exposed in the config map. In a next iteration it will be added in a vault so that security aspects are addressed.
- The deployment is using EC2 instances in the free tier so that no costs are incurred.  