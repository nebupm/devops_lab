# Helper Scripts

## init-backend.sh : Terraform Backend Initialization Script

### Overview

This helper script initializes a Terraform module with an **S3 remote backend** using outputs from the `00-bootstrap` Terraform stack.

It automatically retrieves:

* The S3 state bucket name
* The AWS region

…and uses them to run `terraform init` correctly for any module.

---

### Script Location

```text
scripts/init-backend.sh
```

---

### Prerequisites

* Terraform installed
* `00-bootstrap` directory exists
* `terraform apply` has already been run in `00-bootstrap`
* Script executed from the **project root**

---

### Usage

```bash
./scripts/init-backend.sh <module-directory>
```

#### Examples

Initialize the current directory:

```bash
./scripts/init-backend.sh
```

Initialize a specific module:

```bash
./scripts/init-backend.sh 01-network
```

---

### What the Script Does

1. Verifies the `00-bootstrap` directory exists
2. Reads backend values from Terraform outputs:

   * S3 bucket name
   * AWS region
3. Runs `terraform init` with:

   * S3 backend
   * DynamoDB state locking (`terraform-state-locks`)

---

### Expected Output

```text
✓ Successfully initialized 01-network with S3 backend
Bucket: terraform-state-123456789012-eu-west-1
Region: eu-west-1
```

---
