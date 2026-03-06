# Cloud-Native Provisioner

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-orange.svg)](https://aws.amazon.com/)

A production-ready Infrastructure as Code (IaC) capstone project. This repository uses Terraform to dynamically provision a secure, highly available AWS networking and compute architecture.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Backend Initialization](#backend-initialization)
- [Usage and Deployment](#usage-and-deployment)

## Architecture Overview

Currently, this project provisions the following foundational resources:

- **Networking:** A dedicated Virtual Private Cloud (VPC) with a public subnet, Internet Gateway, and custom routing.
- **Compute:** An Ubuntu 22.04 LTS EC2 instance bootstrapped with an Apache web server.
- **Security:** A custom Security Group restricting inbound traffic to HTTP (Port 80) and SSH (Port 22).
- **State Management:** A remote backend utilizing an AWS S3 bucket for state storage and a DynamoDB table for state locking.

## Prerequisites

Before deploying this infrastructure, ensure you have the following installed and configured:

- **Terraform CLI** (v1.5.0 or later)
- **AWS CLI** (configured with a dedicated, least-privilege programmatic IAM user)

## Backend Initialization

This project requires a remote backend. The following AWS CLI commands were used to provision the state storage in `us-east-1` prior to running Terraform:

```bash
aws s3api create-bucket --bucket ecommerce-capstone-state-martin-123 --region us-east-1
aws s3api put-bucket-versioning --bucket ecommerce-capstone-state-martin-123 --versioning-configuration Status=Enabled --region us-east-1
aws dynamodb create-table --table-name ecommerce-terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
```

## Usage and Deployment

To provision the infrastructure, run the following commands sequentially from the project root:

### Initialize the Working Directory

Downloads providers and connects to the S3 backend:

```bash
terraform init
```

### Format and Validate the Code Syntax

```bash
terraform fmt
terraform validate
```

### Preview the Infrastructure Changes

```bash
terraform plan
```

### Deploy the Resources to AWS

```bash
terraform apply
```

### Tear Down the Infrastructure

To prevent idle cloud charges:

```bash
terraform destroy
```