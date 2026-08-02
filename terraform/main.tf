#############################################
# StrideLux — main.tf
# Provider, backend, and common locals
#############################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Remote state — dedicated bucket (NOT stridelux-frontend).
  # Create the bucket + DynamoDB lock table once, out-of-band or via a
  # separate bootstrap config, then `terraform init`.
  backend "s3" {
    bucket         = "stridelux-terraform-state"
    key            = "stridelux/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  common_tags = {
    project     = "stridelux"
    environment = var.environment
    managed-by  = "terraform"
  }
}
