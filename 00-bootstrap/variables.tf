variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

# Define the region for AWS resources
variable "aws_profile" {
  description = "The AWS profile to use for running the code"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}

variable "force_destroy" {
  description = "Force destroy S3 bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "state_bucket_prefix" {
  description = "Prefix for S3 bucket name (will be suffixed with account-id and region)"
  type        = string
  default     = "terraform-state"
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-locks"
}