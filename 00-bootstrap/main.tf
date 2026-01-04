# ====================================
# TERRAFORM BACKEND SETUP (One-Time)
# Directory: 00-bootstrap/
# ====================================
# This creates the S3 bucket and DynamoDB table for remote state

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# S3 bucket for Terraform state
# S3 bucket for Terraform state with account ID for uniqueness
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.state_bucket_prefix}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = var.environment
    ManagedBy   = "Terraform"
    AccountId   = data.aws_caller_identity.current.account_id
  }
}

# Enable versioning for state history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
