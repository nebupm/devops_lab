#########################################################
# TERRAFORM + PROVIDER
#########################################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend config provided via -backend-config during init
  # DO NOT hardcode bucket name here - it's constructed during init
  backend "s3" {
    key     = "network/terraform.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
