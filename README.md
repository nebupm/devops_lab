# Prometheus & Grafana Lab - Modular Deployment with S3 Backend

## Directory Structure
```
monitoring-lab/
├── 00-bootstrap/        # S3 backend setup (deploy once)
├── 01-network/          # Standalone network infrastructure
├── 02-monitoring/       # Monitoring stack (depends on network)
├── 03-applications/     # Sample applications (depends on network)
├── scripts/             # Helper scripts
│   ├── init-backend.sh  # Initialize any module with S3 backend
│   ├── deploy-all.sh    # Deploy everything in order
│   └── destroy-all.sh   # Destroy everything in reverse order
└── README.md
```

## Initial Setup (One-Time)

### Step 0: Bootstrap S3 Backend
This creates the S3 bucket and DynamoDB table for storing Terraform state.

```bash
cd 00-bootstrap

# The bucket name will automatically be: terraform-state-{account-id}-{region}
vim terraform.tfvars  # Optional: customize prefix

terraform init
terraform apply

# Note the bucket name from outputs
terraform output s3_bucket_name
# Example: terraform-state-123456789012-eu-west-1
```

**Optional**: Migrate bootstrap state to S3 after creation:
```bash
# Add this to 00-bootstrap/main.tf after the resource blocks:
terraform {
  backend "s3" {
    # Use the bucket you just created!
    key            = "bootstrap/terraform.tfstate"
    encrypt        = true
  }
}

# Then migrate
terraform init -migrate-state \
  -backend-config="bucket=terraform-state-123456789012-eu-west-1" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=terraform-state-locks"
```

### Step 1: Deploy Network
```bash
cd 01-network

vi terraform.tfvars  # Configure your settings
cd ..
bash ./scripts/init-backend.sh 01.network
terraform plan
terraform apply
```

More details are in 01.network/README.md

**Why you need -backend-config:**
Terraform's backend block is evaluated BEFORE providers and data sources are initialized, so it can't use `data.aws_caller_identity` to construct the bucket name. You must provide it via the `-backend-config` flag during `terraform init`.

### Step 2: Deploy Monitoring
```bash
cd ../02-monitoring
vim terraform.tfvars  # Add your IP, key name, etc.

bash ../scripts/init-backend.sh .
terraform apply
```

### Step 3: Deploy Applications
```bash
cd ../03-applications
vim terraform.tfvars

bash ../scripts/init-backend.sh .
terraform apply
```

### Quick Deploy (All at Once)
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy everything with prompts
./scripts/deploy-all.sh
```

## Why Can't Terraform Auto-Construct the Bucket Name?

**The Problem:**
Terraform's backend configuration is evaluated in a special "bootstrap" phase that happens BEFORE:
- Providers are initialized
- Data sources can be queried
- Variables are fully evaluated

This means you **cannot** use `data.aws_caller_identity` or any other data sources in the backend block itself.

**The Solution:**
You must provide the bucket name via `-backend-config` during `terraform init`. The helper scripts handle this automatically by:
1. Reading the bucket name from bootstrap's terraform output
2. Passing it to terraform init via `-backend-config`

**However**, once initialized, the modules CAN construct the bucket name using data sources for:
- Remote state data sources (reading other modules' state)
- Validation
- Output display

This is why we use `locals.state_bucket_name` for remote state references, but still need `-backend-config` for the initial backend configuration.

✅ **Team Collaboration**: Multiple people can work on the same infrastructure
✅ **State Locking**: DynamoDB prevents concurrent modifications
✅ **State History**: S3 versioning allows state rollback
✅ **Encryption**: State data encrypted at rest
✅ **Backup**: State is safely stored in S3, not lost if laptop dies
✅ **CI/CD Ready**: Easy integration with automation pipelines

## State Management

### View State
```bash
# List all objects in the state bucket
aws s3 ls s3://my-terraform-state-lab-12345/

# Download a specific state file
terraform state pull > local-state.json
```

### State Locking
When you run `terraform apply`, Terraform automatically:
1. Acquires a lock in DynamoDB
2. Performs the operation
3. Releases the lock

If another user tries to run Terraform while locked, they'll see:
```
Error: Error acquiring the state lock
```

### Recover from Failed Locks
If Terraform crashes and leaves a lock:
```bash
# View the lock
aws dynamodb scan --table-name terraform-state-locks

# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

## Common Operations

### Redeploy Monitoring Only
```bash
cd 02-monitoring
terraform destroy
terraform apply
# State stored in S3: monitoring/terraform.tfstate
# Network state unaffected: network/terraform.tfstate
```

### Scale Applications
```bash
cd 03-applications
terraform apply -var="instance_count=5"
```

### View All Deployed Resources
```bash
# Check what's in each state
cd 01-network && terraform state list
cd ../02-monitoring && terraform state list
cd ../03-applications && terraform state list
```

### Complete Teardown
```bash
# Destroy in reverse dependency order
cd 03-applications && terraform destroy
cd ../02-monitoring && terraform destroy
cd ../01-network && terraform destroy

# Optional: Remove backend infrastructure
cd ../00-bootstrap && terraform destroy
```

## Migrating from Local to S3 Backend

If you already have local state files:

```bash
# 1. Add backend configuration to main.tf
# 2. Run terraform init with migration flag
terraform init -migrate-state

# Terraform will ask: "Do you want to copy existing state to the new backend?"
# Answer: yes
```

## Backend Configuration Best Practices

### Using Backend Config File
Instead of hardcoding in main.tf, use a backend config file:

```bash
# Create backend-config.hcl
cat > backend-config.hcl <<EOF
bucket         = "my-terraform-state-lab-12345"
region         = "eu-west-1"
dynamodb_table = "terraform-state-locks"
encrypt        = true
EOF

# Initialize with config file
terraform init -backend-config=backend-config.hcl
```

### Separate Backends per Environment

```bash
monitoring-lab/
├── 00-bootstrap/
├── 01-network/
│   ├── backend-dev.hcl
│   ├── backend-staging.hcl
│   └── backend-prod.hcl
```

```bash
# Deploy to different environments
terraform init -backend-config=backend-dev.hcl
terraform workspace select dev
terraform apply
```

## Troubleshooting

### Issue: "Error loading state: AccessDenied"
**Solution**: Ensure your AWS credentials have S3 and DynamoDB permissions
```bash
aws sts get-caller-identity
```

### Issue: "Backend initialization required"
**Solution**: Run `terraform init` again

### Issue: State locked by another process
**Solution**: Wait for the other process to complete, or force unlock if needed
```bash
terraform force-unlock <LOCK_ID>
```

### Issue: Bucket name already exists
**Solution**: Choose a different, globally unique bucket name in 00-bootstrap/terraform.tfvars

## Accessing Services

After deployment:
- **Grafana**: http://<monitoring-ip>:3000 (admin/admin)
- **Prometheus**: http://<monitoring-ip>:9090
- **Applications**: Check outputs with `terraform output`
