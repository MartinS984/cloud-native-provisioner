terraform {
  # Instructs Terraform to require AWS provider version 5.x
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configures the remote S3 backend with DynamoDB locking
  backend "s3" {
    bucket         = "ecommerce-capstone-state-martin-123"
    key            = "capstone/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "ecommerce-terraform-locks"
    encrypt        = true
  }
}

# Configures the AWS Provider default region
provider "aws" {
  region = "eu-central-1"
}