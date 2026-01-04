output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_config" {
  description = "Backend configuration to use in other modules"
  value       = <<-EOF
    backend "s3" {
      bucket         = "${aws_s3_bucket.terraform_state.id}"
      key            = "path/to/state/terraform.tfstate"  # Change per module
      region         = "${var.aws_region}"
      dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
      encrypt        = true
    }
  EOF
}

output "example_backend_init" {
  description = "Example terraform init command with backend config"
  value       = <<-EOF
    terraform init \
      -backend-config="bucket=${aws_s3_bucket.terraform_state.id}" \
      -backend-config="region=${var.aws_region}" \
      -backend-config="dynamodb_table=${aws_dynamodb_table.terraform_locks.name}"
  EOF
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
