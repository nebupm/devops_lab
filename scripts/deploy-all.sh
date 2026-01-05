#!/usr/bin/env bash

# Deploy all modules in order
# Usage: ./scripts/deploy-all.sh

set -euo pipefail

PROJECT_ROOT=$(pwd)
SCRIPT_DIR="$PROJECT_ROOT/scripts"

echo "========================================"
echo "Deploying Monitoring Lab Infrastructure"
echo "========================================"

# Step 1: Bootstrap (if not already done)
echo ""
echo "Step 1: Bootstrap S3 Backend..."
cd "$PROJECT_ROOT/00-bootstrap"
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    echo "Initializing bootstrap..."
    terraform init
    echo "Creating S3 backend infrastructure..."
    terraform apply -auto-approve
else
    echo "✓ Bootstrap already exists, skipping..."
fi

# Get bucket name
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
echo "✓ Using S3 bucket: $BUCKET_NAME"

# Step 2: Network
echo ""
echo "Step 2: Deploying Network..."
cd "$PROJECT_ROOT/01-network"
bash "$SCRIPT_DIR/init-backend.sh" .
terraform plan
read -p "Apply network changes? (yes/no): " apply_network
if [ "$apply_network" = "yes" ]; then
    terraform apply
    echo "✓ Network deployed"
else
    echo "Skipping network apply"
fi

# Step 3: Monitoring
echo ""
echo "Step 3: Deploying Monitoring..."
cd "$PROJECT_ROOT/02-monitoring"
bash "$SCRIPT_DIR/init-backend.sh" .
terraform plan
read -p "Apply monitoring changes? (yes/no): " apply_monitoring
if [ "$apply_monitoring" = "yes" ]; then
    terraform apply
    echo "✓ Monitoring deployed"
    
    # Show URLs
    echo ""
    echo "Monitoring URLs:"
    terraform output grafana_url
    terraform output prometheus_url
else
    echo "Skipping monitoring apply"
fi

# Step 4: Applications
echo ""
echo "Step 4: Deploying Applications..."
cd "$PROJECT_ROOT/03-applications"
bash "$SCRIPT_DIR/init-backend.sh" .
terraform plan
read -p "Apply application changes? (yes/no): " apply_apps
if [ "$apply_apps" = "yes" ]; then
    terraform apply
    echo "✓ Applications deployed"
else
    echo "Skipping applications apply"
fi

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"