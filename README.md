# My Terraform Project

Welcome to my personal Terraform project! This repository contains Terraform configurations that provision and manage infrastructure in AWS. The goal of this project is to automate the deployment of a simple web application infrastructure, including EC2 instances, load balancing, security groups, and a MySQL database, all managed by Terraform.

## Project Overview

This Terraform configuration sets up the following resources in AWS:

- **EC2 Instances**: Two web servers (`webserver1` and `webserver2`) that run an Ubuntu-based AMI.
- **Security Group**: A security group that allows HTTP (port 80) traffic to the web servers.
- **S3 Bucket**: A versioned S3 bucket for storing web app data.
- **Load Balancer**: An AWS Application Load Balancer (ALB) to distribute traffic across the web servers.
- **RDS Database**: A MySQL database hosted on AWS RDS.
- **Auto Scaling Group**: Automatically scales the number of web servers based on traffic.
- **DynamoDB**: Used for Terraform state locking when using an S3 backend.

### Key Files:

- **main.tf**: Contains the primary infrastructure configuration, including EC2 instances, security groups, load balancers, etc.
- **backend.tf**: Configures the backend for storing the Terraform state file in an S3 bucket and DynamoDB table for state locking.
- **variables.tf** (optional): If you decide to make your project more flexible, you can define variables here.
- **outputs.tf** (optional): You can define output values to display information after deployment, such as instance IDs, public IPs, etc.

## Terraform Workflow

1. **`terraform init`**: Initializes the working directory containing Terraform configuration files and downloads required provider plugins.
2. **`terraform plan`**: Creates an execution plan, showing you what Terraform will do when you apply the configuration.
3. **`terraform apply`**: Applies the changes defined in the configuration files, creating the infrastructure.
4. **`terraform destroy`**: Removes all infrastructure created by Terraform.

## Configuration and Customization

You can customize the following aspects of the project:

- **AMI ID**: Replace the AMI IDs in `main.tf` with the IDs of your desired images (e.g., Ubuntu 24.04 LTS).
- **Instance Types**: Change the instance type for EC2 instances in the `main.tf` file.
- **Region**: Change the AWS region in the `provider` block if you'd like to deploy to a different region.

## Additional Notes

- **State Management**: This project uses **remote state** with an S3 backend and DynamoDB for state locking to ensure that multiple users or processes don't overwrite each other's work.
- **Security**: Ensure that your AWS credentials and sensitive data (e.g., RDS database passwords) are handled securely. You might want to use `aws_secretsmanager` or similar mechanisms for storing sensitive data.
- **Autoscaling**: The auto-scaling group is configured to scale between 2 and 4 instances depending on traffic.
