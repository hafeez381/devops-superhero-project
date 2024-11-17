# DevOps Superhero Project

## **Introduction**

This project automates the setup of a **DevOps pipeline** for **CI/CD** and code quality management using **Terraform**, **Ansible**, and **Docker Compose**. The infrastructure is provisioned on **AWS**, with Terraform creating a **VPC**, **subnet**, and a **t2.micro EC2 instance**. Ansible is used to configure the EC2 instance by installing Docker and deploying services like **Jenkins** and **SonarQube**. Docker Compose orchestrates the deployment of Jenkins, SonarQube, and a **PostgreSQL database** for SonarQube. This end-to-end setup streamlines the development process, enabling efficient **CI/CD workflows** and **static code analysis** in a cloud environment. This project was presented to the DevOps team at Tkxel as part of my final internship assignment.

---------------------------------------------------------------------

## CI/CD Workflow

Directory: '.github/workflows'
The CI/CD workflow is defined in the ci-cd.yml file. It is executed on every push or pull request made to the main branch. The workflow includes the following jobs:

1. **Terraform**: This job is responsible for provisioning AWS resources using Terraform. It sets up the required providers, initializes the VPC, creates subnets, attaches an internet gateway and configures route tables.

2. **Ansible**: This job is triggered after the Terraform job completes. It uses Ansible to copy the docker-compose.yml file to the remote system and runs it.

Each job is executed on an Ubuntu virtual machine, and the necessary configurations and dependencies are set up through the running the scripts.

---------------------------------------------------------------------

## Terraform Scripts

Directory: 'terraform/'
The Terraform script is divided into multiple files which define the AWS resources and configurations required for the VPC setup.

1. `backend.tf`: This file defines the backend configuration for storing Terraform state remotely in an S3 bucket. The state file will be stored in the `devops-superhero-bucket` bucket under the `terraformstate.tfstate` key.
2. `variables.tf`: This file defines the variables used across the Terraform configuration, such as CIDR blocks for the VPC and subnet, availability zones, and instance types.
3. `main.tf`: The main Terraform configuration file defines the infrastructure as code. It includes resources for provisioning an AWS VPC, public subnet, internet gateway, security group, and EC2 instance.

The script performs the following tasks:
  - Defines the AWS region (`us-east-1`).
  - Retrieves an SSH private key stored in AWS Secrets Manager.
  - Creates a VPC with the CIDR block defined in `variables.tf`.
  - Defines a public subnet and associates it with the VPC and the internet gateway.
  - Opens ports for SSH (22), HTTP (80), Jenkins (8080), and other necessary services.
  - Deploys a `t2.micro` EC2 instance using the Ubuntu AMI and connects it to the created security group and subnet.

---------------------------------------------------------------------

## Ansible Script

Directory: 'ansible/'
The Ansible Playbook, defined in the `docker-setup.yml`, is triggered after the Terraform script is completed and is responsible for installing Docker and Docker Compose on the EC2 instance and deploys the Docker containers defined in `docker-compose.yml`.

The script performs the following tasks:
  - Installs necessary packages for Docker installation.
  - Adds the Docker GPG key to verify the authenticity of the Docker package.
  - Installs Docker and Docker Compose on the EC2 instance.
  - Ensures that the Docker service is running and enabled.
  - Uses Docker Compose to deploy the containers defined in `docker-compose.yml`.

---------------------------------------------------------------------

## Docker Compose Configuration

Directory: 'ansible/'
The docker-compose.yml file defines the services and configurations required for running the Jenkins and SonarQube containers. It includes:

1. **Jenkins**: This service is based on the "jenkins/jenkins:lts" image. It runs on port 8080 and 50000 and mounts the Jenkins configuration and Docker socket volumes for persistence and access to the host's Docker daemon.

2. **SonarQube**: This service is based on the "sonarqube:latest" image. It runs on port 9000 and depends on the "db" service. It sets environment variables for the SonarQube database connection.

3. **DB**: This service is based on the "postgres:latest" image. It runs a PostgreSQL database for SonarQube and sets the necessary environment variables.

The docker-compose.yml file ensures that the Jenkins and SonarQube containers are properly configured and running on the remote system. Make sure that EC2 instance has opened the ingress ports mentioned above.

---------------------------------------------------------------------

## Conclusion

In this documentation, we have provided a detailed explanation of the CI/CD pipeline implemented in this project. The pipeline includes GitHub Actions for triggering the workflow, which runs Terraform for provisioning AWS resources, at last triggers Ansible for configuring the remote system and pinging Docker Compose for running the application containers.

By following this pipeline, you can automate the deployment and configuration of your application. Add 'nginx' and complete SonarQube and Jenkins Pipeline to Deploy your app. Super time saving and ensuring consistency in your DevOps processes!

---------------------------------------------------------------------

## Important:

1. Ensure the AWS credentials are correctly set and that the S3 bucket is properly initialized to avoid creating new resources on every pipeline run.
2. Ensure the correct public IP is added to the `inventory.ini` file and that the SSH keys in GitHub Secrets match the EC2 instance's key pair.
4. 'docker-compose.yml' is stored 'locally' and then copied to remote system through ansible.
5. 'docker-compose.yml' allows Jenkins to host on the remote system in this project. Beware! it is a bad practice and is depriciated.

---------------------------------------------------------------------

## **Prerequisites**

Before using this repository, ensure you have the following:

1. **AWS Account**:  
   - Access to create and manage resources like VPCs, EC2 instances, and S3 buckets.  
   - IAM credentials (Access Key and Secret Key) for configuring Terraform.

2. **Local System Requirements**:  
   - **Terraform**: Installed and configured (version 1.0.3 or later).  
   - **Ansible**: Installed (latest version recommended).  
   - **Docker**: Installed and running, with Docker Compose installed.  

3. **GitHub Account**:  
   - A repository with configured **GitHub Actions**.  
   - Secrets for AWS credentials added to GitHub:  
     - `TF_USER_AWS_KEY`: AWS Access Key.  
     - `TF_USER_AWS_SECRET`: AWS Secret Key.  

4. **SSH Key Pair**:  
   - A valid SSH key pair for accessing the EC2 instance.  
   - The private key securely stored for use with Ansible.

5. **Required Tools**:  
   - **Git**: To clone the repository and manage version control.  
   - **Python and pip**: Required for managing Ansible and its dependencies.

6. **Environment Configurations**:  
   - Ensure `terraform` and `docker-compose` commands are accessible via the terminal.  
   - Sufficient permissions on your local system to install packages and run scripts.

---------------------------------------------------------------------

## Getting Started

Follow these steps to set up and run the project:

### 1. Clone the Repository
```bash
git clone https://github.com/hafeez381/devops-superhero-project.git
cd devops-superhero-project
```
### 2. Configure Terraform Backend
Update the `backend.tf` file with your S3 bucket name and region.

### 3. Update Terraform Variables
Modify the `main.tf` and `variables.tf ` files with your specific configurations.

### 4. Commit and Push Changes:
   ```sh
   git add .
   git commit -m "Initial setup"
   git push origin dev
   ```

### 5. Trigger CI/CD Pipeline:
The pipeline will automatically run on every pull request to the main branch.

---------------------------------------------------------------------

## References

Here are some useful references for further reading:

1. [Terraform Documentation](https://www.terraform.io/docs/index.html)
2. [Ansible Documentation](https://docs.ansible.com/)
3. [Docker Compose Documentation](https://docs.docker.com/compose/)
4. [GitHub Actions Documentation](https://docs.github.com/en/actions)

---------------------------------------------------------------------
