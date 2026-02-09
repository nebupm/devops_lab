# The AWS region to deploy resources in
aws_region = "eu-west-2"

# The AWS profile to use for running the code
aws_profile = "default"

# The environment name for tagging resources.
environment = "lab"

# The name prefix for the S3 bucket to store Terraform state.
state_bucket_prefix = "terraform-state" # Will become: terraform-state-123456789012-eu-west-1

# The name of the DynamoDB table for state locking.
dynamodb_table_name = "terraform-state-locks"

# Whether to force destroy the S3 bucket even if it contains objects.
force_destroy = false