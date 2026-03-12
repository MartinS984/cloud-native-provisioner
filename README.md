# Cloud-Native Provisioner

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-orange.svg)](https://aws.amazon.com/)
[![Terraform CI/CD Pipeline](https://github.com/MartinS984/cloud-native-provisioner/actions/workflows/terraform.yml/badge.svg)](https://github.com/MartinS984/cloud-native-provisioner/actions/workflows/terraform.yml)
[![Docker](https://img.shields.io/badge/Docker-Containerization-2496ED.svg?logo=docker&logoColor=white)](https://www.docker.com/)

A production-ready Infrastructure as Code (IaC) capstone project. This repository uses Terraform to dynamically provision a secure, highly available, and load-balanced AWS networking and compute architecture.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Visual Representation](#visual-representation)
- [Prerequisites](#prerequisites)
- [Backend Initialization](#backend-initialization)
- [Usage and Deployment](#usage-and-deployment)
- [Outputs](#outputs)

## Architecture Overview

Currently, this project provisions the following foundational resources:

- **High-Availability Networking:** A dedicated Virtual Private Cloud (VPC) spanning multiple Availability Zones (`us-east-1a` and `us-east-1b`) with public subnets, an Internet Gateway, and custom routing.
- **Load Balancing:** An AWS Application Load Balancer (ALB) routing internet traffic securely to Target Groups.
- **Compute & Auto Scaling:** An Auto Scaling Group (ASG) managing a fault-tolerant fleet of Ubuntu 22.04 LTS instances across multiple Availability Zones. 
- **Bootstrapping:** EC2 Launch Templates utilizing an IMDSv2 `user_data` script to automatically configure Apache web servers and dynamically display the active Availability Zone for Load Balancer verification.
- **Security:** A custom Security Group restricting inbound traffic to HTTP (Port 80) and SSH (Port 22).
- **State Management:** A remote backend utilizing an AWS S3 bucket for state storage and a DynamoDB table for state locking.

## Visual Representation

Check out the `visual representation.txt` file in the root directory for an ASCII map of the network flow and resource dependencies.

## Prerequisites

Before deploying this infrastructure, ensure you have the following installed and configured:

- **Terraform CLI** (v1.5.0 or later)
- **AWS CLI** (configured with a dedicated, least-privilege programmatic IAM user)

## Backend Initialization

This project requires a remote backend. The following AWS CLI commands can be used to provision the state storage in `us-east-1` prior to running Terraform. 

*Note: S3 bucket names must be globally unique. Replace the `<PLACEHOLDER>` values with your own unique naming convention before running.*

```bash
aws s3api create-bucket --bucket <YOUR_UNIQUE_BUCKET_NAME> --region us-east-1
aws s3api put-bucket-versioning --bucket <YOUR_UNIQUE_BUCKET_NAME> --versioning-configuration Status=Enabled --region us-east-1
aws dynamodb create-table --table-name <YOUR_UNIQUE_TABLE_NAME> --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
```
Important: After creating your bucket and table, ensure you update the backend "s3" configuration block in your .tf files to match your newly created resource names.

## Usage and Deployment

To provision the infrastructure, run the following commands sequentially from the project root:

1. **Initialize the Working Directory**
   Downloads providers and connects to the S3 backend:
   ```bash
   terraform init
   ```

2. **Format and Validate the Code**
   ```bash
   terraform fmt
   terraform validate
   ```

3. **Preview the Infrastructure Changes**
   ```bash
   terraform plan
   ```

4. **Deploy the Resources to AWS**
   ```bash
   terraform apply
   ```

## Outputs

Upon a successful `terraform apply`, the terminal will output the live DNS name of the Application Load Balancer. Paste this URL into your browser to view the web server, and refresh the page to see the Load Balancer distribute traffic across Availability Zones:

```
Outputs:
alb_dns_name = "ecommerce-app-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com"
```

## Tear Down the Infrastructure
To prevent idle cloud charges:

```bash
terraform destroy
```