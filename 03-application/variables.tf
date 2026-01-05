# 03-applications/variables.tf
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
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of application instances"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "sample-app"
}