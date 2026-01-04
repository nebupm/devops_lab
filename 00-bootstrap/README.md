# Terraform Backend Bootstrap (S3 + DynamoDB)

## Overview

This Terraform configuration bootstraps a **remote backend** for Terraform using:

* **Amazon S3** for storing Terraform state
* **Amazon DynamoDB** for state locking and concurrency control

This setup is intended to be run **once per AWS account/region** before deploying any other Terraform modules. All other Terraform configurations can then reference this backend to enable safe, shared state management.

---

## Directory Structure

```text
00-bootstrap/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

---

## What This Creates

### S3 Bucket (Terraform State)

* Globally unique bucket name using:

  ```
  <state_bucket_prefix>-<account-id>-<region>
  ```
* Versioning enabled (state history & rollback)
* Server-side encryption (AES-256)
* Public access fully blocked

### DynamoDB Table (State Locking)

* Used by Terraform to prevent concurrent state changes
* On-demand billing (`PAY_PER_REQUEST`)
* Primary key: `LockID`

---

## Prerequisites

* Terraform `>= 1.3`
* AWS CLI configured with sufficient permissions
* An AWS account
* IAM permissions for:

  * S3 (create bucket, encryption, versioning)
  * DynamoDB (create table)
  * STS (GetCallerIdentity)

---

## Providers

| Provider | Version  |
| -------- | -------- |
| AWS      | `~> 5.0` |

---

## Configuration

### Variables

| Name                  | Description                    | Default                 |
| --------------------- | ------------------------------ | ----------------------- |
| `aws_region`          | AWS region to deploy resources | `eu-west-2`             |
| `environment`         | Environment name               | `lab`                   |
| `state_bucket_prefix` | Prefix for S3 state bucket     | `terraform-state`       |
| `dynamodb_table_name` | DynamoDB table name for locks  | `terraform-state-locks` |

### terraform.tfvars

```hcl
aws_region           = "eu-west-2"
environment          = "lab"
state_bucket_prefix  = "terraform-state"
dynamodb_table_name  = "terraform-state-locks"
```

---

## Usage

### 1. Initialize Terraform

```bash
cd 00-bootstrap
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Apply the Bootstrap Resources

```bash
terraform apply
```

> ⚠️ This should only be run **once** per AWS account and region.

---

## Outputs

After apply, Terraform will output:

| Output                 | Description                             |
| ---------------------- | --------------------------------------- |
| `s3_bucket_name`       | Name of the Terraform state bucket      |
| `s3_bucket_arn`        | ARN of the S3 bucket                    |
| `dynamodb_table_name`  | DynamoDB table used for state locking   |
| `account_id`           | AWS Account ID                          |
| `backend_config`       | Example backend block for other modules |
| `example_backend_init` | Example `terraform init` command        |

---

## Using the Backend in Other Terraform Modules

### Backend Configuration Example

Copy and adapt the backend configuration output into your other Terraform modules:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-123456789012-eu-west-2"
    key            = "network/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

> 🔹 **Important:**
>
> * Change the `key` per module (e.g., `vpc/terraform.tfstate`, `eks/terraform.tfstate`)
> * Backend configuration **cannot** use variables

---

## Best Practices

* Use **one backend per AWS account/region**
* Separate state files per module using unique `key` values
* Never delete the S3 bucket or DynamoDB table once in use
* Enable MFA and least-privilege IAM policies
* Keep bootstrap code isolated from application infrastructure

---

## Cleanup (Optional)

If you truly want to destroy the backend (not recommended once in use):

```bash
terraform destroy
```

> ⚠️ Make sure **no other Terraform projects** are using this backend before destroying it.

---

## Migrate the Terraform State File (Optional)

If you want to migrate the statefile to the remove S3 bucket, then run the following command to do so.

```bash
terraform init -migrate-state -backend-config="bucket=terraform-state-123456789012-eu-west-2"
```

---


## License

MIT / Apache 2.0 (choose as appropriate)
