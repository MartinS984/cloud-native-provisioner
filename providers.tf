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
    bucket         = "ecommerce-capstone-state-martin-useast1"
    key            = "capstone/terraform.tfstate"
    region         = "us-east-1" # <--- This must be us-east-1
    dynamodb_table = "ecommerce-terraform-locks-useast1"
    encrypt        = true
  }
}

# Configures the AWS Provider default region
provider "aws" {
  region = var.aws_region
}
