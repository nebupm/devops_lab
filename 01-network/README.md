# Terraform AWS Network (VPC + Subnets)

## Overview

This Terraform configuration provisions a **standalone AWS network layer**, including:

* A Virtual Private Cloud (VPC)
* Public and private subnets across one or more Availability Zones
* An Internet Gateway
* Public route tables
* A baseline security group
* Remote state stored in S3 with DynamoDB locking

This module is intended to be deployed **after** the Terraform backend bootstrap (`00-bootstrap`) has been completed.

---

## Directory Context

```text
01-network/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

---

## Architecture

### Resources Created

| Resource         | Description                      |
| ---------------- | -------------------------------- |
| VPC              | Primary network boundary         |
| Public Subnets   | One per AZ, internet-facing      |
| Private Subnets  | One per AZ, internal-only        |
| Internet Gateway | Enables outbound internet access |
| Route Table      | Routes public traffic via IGW    |
| Security Group   | Baseline VPC-level security      |
| S3 Backend       | Remote Terraform state           |
| DynamoDB         | State locking                    |

---

## Backend Configuration

This module uses a **remote S3 backend** with DynamoDB locking.

The backend bucket and table **must already exist** and are created by the `00-bootstrap` stack.

```hcl
terraform {
  backend "s3" {
    key     = "network/terraform.tfstate"
    encrypt = true
  }
}
```

Backend configuration values (bucket, region, DynamoDB table) are supplied during `terraform init` via `-backend-config`.

---

## Prerequisites

* Terraform `>= 1.3`
* AWS CLI configured
* Bootstrap backend already deployed
* IAM permissions for:

  * VPC
  * Subnets
  * Route tables
  * Internet Gateway
  * Security Groups
  * S3 & DynamoDB (state access)

---

## Providers

| Provider | Version  |
| -------- | -------- |
| AWS      | `~> 5.0` |

---

## Configuration Variables

### Required

| Variable           | Description                              |
| ------------------ | ---------------------------------------- |
| `allowed_ssh_cidr` | CIDR block allowed to SSH (e.g. your IP) |

### Optional (Defaults Provided)

| Variable              | Default                 | Description          |
| --------------------- | ----------------------- | -------------------- |
| `aws_region`          | `eu-west-2`             | AWS region           |
| `aws_profile`         | `default`               | AWS CLI profile      |
| `environment`         | `lab`                   | Environment tag      |
| `vpc_cidr`            | `10.0.0.0/16`           | VPC CIDR             |
| `availability_zones`  | `1`                     | Number of AZs        |
| `state_bucket_prefix` | `terraform-state`       | Must match bootstrap |
| `dynamodb_table_name` | `terraform-state-locks` | State locking table  |

---

## Subnet Design

* **Public subnets**

  * One per Availability Zone
  * Auto-assign public IPs
  * Routed to the Internet Gateway

* **Private subnets**

  * One per Availability Zone
  * No direct internet access
  * Intended for internal workloads (ECS, EKS, RDS, etc.)

CIDR blocks are calculated automatically using `cidrsubnet()` to avoid overlap and manual errors.

---

## Security Group

The default security group allows:

* SSH (port 22) from a configurable CIDR
* All internal VPC traffic
* All outbound traffic

This group is intended as a **baseline** and should be refined per workload.

---

## Usage

### 1. Initialize Terraform

Use the helper script in ```../scripts/init-backend.sh```

Running it from the root dir.
./scripts/init-backend.sh 01-network

```

Or you can manually initialise it using the following command.
```bash
cd 01-network
BUCKET=$(cd ../00-bootstrap && terraform output -raw s3_bucket_name)
terraform init \
  -backend-config="bucket=$BUCKET" \
  -backend-config="region=<REGION of your CHOICE>" \
  -backend-config="dynamodb_table=terraform-state-locks"
```

---

### 2. Review the Plan

```bash
terraform plan
```

---

### 3. Apply the Configuration

```bash
terraform apply
```

---

## Outputs

| Output               | Description                 |
| -------------------- | --------------------------- |
| `vpc_id`             | VPC ID                      |
| `vpc_cidr`           | VPC CIDR                    |
| `public_subnet_ids`  | Public subnet IDs           |
| `private_subnet_ids` | Private subnet IDs          |
| `aws_region`         | AWS region                  |
| `environment`        | Environment name            |
| `state_bucket_name`  | Constructed S3 state bucket |

These outputs are designed to be **consumed by downstream modules** (EKS, ECS, EC2, RDS, etc.).

---

## Cost Considerations

* **Subnets are free**
* **VPC is free**
* Costs only arise when adding:

  * NAT Gateways
  * Load Balancers
  * EC2 / EKS / RDS
  * Cross-AZ traffic

Using multiple AZs improves availability but may increase costs when additional services are introduced.

---

## Best Practices

* Use **1 AZ** for labs and development
* Use **2–3 AZs** for production
* Do not hardcode Availability Zones
* Keep network state separate from application stacks
* Never delete the backend bucket while in use

---

## Cleanup

To destroy the network (ensure nothing depends on it):

```bash
terraform destroy
```

---
