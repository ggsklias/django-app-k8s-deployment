# Deployment Processes

## Table of Contents

- [Summary](#summary)
- [Local Deployment Process](#local-deployment-process)
  - [Prerequisites](#prerequisites)
  - [Actions](#actions)
- [GitLab Deployment Process](#gitlab-deployment-process)
  - [Prerequisites](#prerequisites-1)
  - [Actions](#actions-1)

## Summary

**AWS Infrastructure Deployment with Terraform, Ansible & Kubernetes**

- Developed infrastructure automation to deploy AWS resources using Terraform.
- Automated provisioning with Ansible to:
  - Install prerequisites on EC2 instances and configure Amazon Linux 2 for Kubernetes.
  - Deploy a Django application with PostgreSQL on a Kubernetes worker node.
  - Overcome the lack of native Docker support in Kubernetes by using buildkit and containerd.
  - Expose the application to the web through “one-button” execution of the infrastructure.
- Utilizes two deployment approaches:
  - **Local Execution:** For testing and development with a single Ansible playbook.
  - **GitLab Deployment:** For automated, production-ready deployments triggered via GitLab CI.
  
**Technologies:** Terraform, Ansible, Kubernetes, buildkit, Docker, Django, Python, PostgreSQL  

---

## Local Deployment Process

### Prerequisites

1. **AWS Environment Variables:**  
   Export AWS environment variables locally to ensure proper communication with AWS.

2. **SSH Key:**  
   Ensure that the `ssh_key.pem` is present in the local folder so that Ansible can connect to the EC2 instances.

### Actions

1. **Infrastructure Provisioning:**  
   Run `python3 provision.py` to spin up the EC2 instances with the correct networking configuration.

2. **Ansible Playbook Execution:**  
   Execute the playbook with the following command:
   ```bash
   ansible-playbook -i inventory.ini manual_provisioning_cluster.yml
   ```
   This playbook performs the following tasks:
   - Installs OS prerequisites (Python version, configures OS for Kubernetes), containerd, and buildkit.
   - Builds the Docker image of the `djangoarticleapp` using buildkit and adds it to the containerd local registry.
   - Installs Kubernetes.
   - Initiates Kubernetes and ensures that the worker node joins the master.
   - Applies all Kubernetes manifests, starting the Django application and PostgreSQL database on the worker node.
   - Communicates the public IP address for accessing the application to the user.

---

## GitLab Deployment Process

### Prerequisites

1. **AWS Environment Variables:**  
   Add the AWS environment variables in GitLab CI/CD variables so that they are accessible during pipeline execution.

2. **SSH Private Key:**  
   Add the SSH private key to a GitLab variable called `SSH_PRIVATE_KEY`.

3. **GitLab Registry Credentials:**  
   Create GitLab variables for `GITLAB_EMAIL`, `GITLAB_USERNAME`, and `GITLAB_REGISTRY_TOKEN` to enable the creation of a Kubernetes secret for registry access.

### Actions

1. **Pipeline Trigger:**  
   A code change triggers the GitLab pipeline which performs the following tasks:

   - **Docker Image Build:**  
     Builds the Docker image of the Django application and uploads it to the GitLab CI registry.

   - **Infrastructure Provisioning:**  
     Uses Terraform to provision EC2 instances with the proper networking.

   - **OS and Kubernetes Configuration:**  
     Uses Ansible to install OS prerequisites and configure Kubernetes and containerd on all hosts (without building the Django image) by running:  
     ```bash
     ansible-playbook -i inventory.ini gitlab_provisioning_k8s_cluster.yml
     ```

   - **Application Deployment:**  
     Uses Ansible to deploy the application on the worker node by running:
     ```bash
     ansible-playbook -i inventory.ini deploy_app.yml
     ```
     This step applies manifests, starts the Django application and PostgreSQL database, and communicates the application IP to the user.

   - **Post-Deployment:**  
     Waits for 10 minutes before tearing down the Terraform-provisioned infrastructure.
