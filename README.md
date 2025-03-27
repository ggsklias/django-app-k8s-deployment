# Deployment Processes

## Table of Contents

- [Summary](#summary)
- [Local Deployment Process](#local-deployment-process)
  - [Prerequisites](#prerequisites)
  - [Actions](#actions)
- [GitLab Deployment Process](#gitlab-deployment-process)
  - [Prerequisites](#prerequisites-1)
  - [Actions](#actions-1)
- [High Availability & Load Balancing Setup](#high-availability--load-balancing-setup)

---

## Summary

**AWS Infrastructure Deployment with Terraform, Ansible, Kubernetes & ALB**

- **High Availability:** Provisioned a redundant Kubernetes cluster consisting of 3 master nodes and 2 worker nodes to ensure resilience and fault tolerance.
- **ALB Integration:** Implemented an Application Load Balancer (ALB) with a properly configured listener and target groups. This design distributes incoming traffic across the worker nodes, enabling efficient load distribution and seamless failover.
- **Automation:** Utilized Terraform for AWS resource provisioning, Ansible for OS and Kubernetes configuration, and GitLab CI/CD for streamlined production deployments.
- **Deployment Strategies:** Supports both local testing (single-playbook execution) and automated, production-ready deployments via GitLab pipelines.
- **Monitoring:** Implemented Prometheus monitoring through helm to monitor cpu, memory, IOPS while stress testing. 

**Technologies:** Terraform, Ansible, Kubernetes, containerd, buildkit, Docker, Django, Python, PostgreSQL, AWS ALB

---

## Local Deployment Process

### Prerequisites

1. **AWS Environment Variables:**  
   Ensure AWS environment variables are exported locally for proper communication with AWS.

2. **SSH Key:**  
   The `ssh_key.pem` file must be present in the local folder to allow Ansible to connect to the EC2 instances.

### Actions

1. **Infrastructure Provisioning:**  
   Run the following command to provision the EC2 instances with the correct networking configuration:
   ```bash
   python3 provision.py
   ```

2. **Ansible Playbook Execution:**  
   Execute the playbook with:
   ```bash
   ansible-playbook -i inventory.ini manual_provisioning_cluster.yml
   ```
   This playbook performs:
   - Installation of OS prerequisites (Python, containerd, buildkit) and Kubernetes setup.
   - Building and loading the Docker image for the `djangoarticleapp` using buildkit.
   - Initiating the Kubernetes cluster and ensuring that the worker node joins the master.
   - Applying Kubernetes manifests to start the Django application and PostgreSQL database.
   - Displaying the public IP address for accessing the application.

---

## GitLab Deployment Process

### Prerequisites

1. **AWS Environment Variables:**  
   Add the necessary AWS environment variables in GitLab CI/CD settings.

2. **SSH Private Key:**  
   Store the SSH private key in a GitLab variable named `SSH_PRIVATE_KEY`.

3. **GitLab Registry Credentials:**  
   Define variables for `GITLAB_EMAIL`, `GITLAB_USERNAME`, and `GITLAB_REGISTRY_TOKEN` to facilitate the creation of a Kubernetes secret for registry access.

### Actions

1. **Pipeline Trigger:**  
   A commit or merge request automatically triggers the GitLab pipeline which performs the following tasks:

   - **Docker Image Build:**  
     Builds the Docker image of the Django application and uploads it to the GitLab registry.

   - **Infrastructure Provisioning:**  
     Uses Terraform to:
     - Provision EC2 instances.
     - Spin up a **high-availability Kubernetes cluster** with 3 masters and 2 workers.
     - Set up the necessary networking and security groups.

   - **ALB Setup:**  
     Provisions an Application Load Balancer (ALB) along with:
     - A listener for incoming HTTP/HTTPS traffic.
     - Target groups configured to automatically register the worker nodes.
     - Routing rules that ensure proper distribution of requests to the application containers.

   - **OS and Kubernetes Configuration:**  
     Runs the following Ansible playbook to configure OS prerequisites, containerd, buildkit, and Kubernetes on all nodes:
     ```bash
     ansible-playbook -i inventory.ini gitlab_provisioning_k8s_cluster.yml
     ```

   - **Application Deployment:**  
     Deploys the Django application and PostgreSQL database on the worker nodes by applying Kubernetes manifests, with 4 replicas and rolling update strategy to ensure no downtime during the upgrade of the application. 
     ```bash
     ansible-playbook -i inventory.ini deploy_app.yml
     ```
     This step also ensures that the ALB target groups are correctly updated with healthy endpoints.

---

## High Availability & Load Balancing Setup

- **Cluster Redundancy:**  
  The deployment now leverages a three-master, two-worker node setup. This redundancy minimizes downtime and enhances fault tolerance during node failures or maintenance events.

- **ALB Configuration:**  
  The Application Load Balancer is set up with:
  - **Listeners:** Configured to handle incoming traffic on specified ports (e.g., 80 for HTTP, 443 for HTTPS).
  - **Target Groups:** Dynamically register healthy worker nodes, ensuring efficient traffic routing.
  - **Health Checks:** Continuously monitor the worker nodes to automatically remove any unresponsive endpoints from the target group.
  
- **Rolling Updates:** The application is deployed using a rolling update strategy with 4 replicas, ensuring that during upgrades, healthy pods continue to serve traffic and no downtime occurs.

- **Integration with CI/CD:**  
  Both Terraform and Ansible scripts have been updated to include ALB and high-availability settings. This integration is fully automated within the GitLab pipeline, providing a production-ready, resilient deployment environment.


