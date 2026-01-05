#!/usr/bin/env bash
# Destroy all infrastructure in reverse order
# Usage: ./scripts/destroy-all.sh

set -euo pipefail

PROJECT_ROOT=$(pwd)

echo "========================================"
echo "WARNING: This will destroy ALL infrastructure"
echo "========================================"
read -p "Are you sure? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted"
    exit 0
fi

# Destroy in reverse order
echo ""
echo "Step 1: Destroying Applications..."
cd "$PROJECT_ROOT/03-applications"
if [ -f ".terraform/terraform.tfstate" ]; then
    terraform destroy -auto-approve
    echo "✓ Applications destroyed"
fi

echo ""
echo "Step 2: Destroying Monitoring..."
cd "$PROJECT_ROOT/02-monitoring"
if [ -f ".terraform/terraform.tfstate" ]; then
    terraform destroy -auto-approve
    echo "✓ Monitoring destroyed"
fi

echo ""
echo "Step 3: Destroying Network..."
cd "$PROJECT_ROOT/01-network"
if [ -f ".terraform/terraform.tfstate" ]; then
    terraform destroy -auto-approve
    echo "✓ Network destroyed"
fi

echo ""
read -p "Destroy S3 backend infrastructure? (yes/no): " destroy_backend
if [ "$destroy_backend" = "yes" ]; then
    echo "Step 4: Destroying Bootstrap..."
    cd "$PROJECT_ROOT/00-bootstrap"
    terraform destroy -auto-approve
    echo "✓ Bootstrap destroyed"
fi

echo ""
echo "========================================"
echo "Destruction Complete!"
echo "========================================"