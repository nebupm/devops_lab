# 02-monitoring/variables.tf
variable "aws_region" {
  description = "AWS region (should match network deployment)"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "state_bucket_prefix" {
  description = "Prefix for S3 state bucket (must match bootstrap)"
  type        = string
  default     = "terraform-state"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-locks"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}
