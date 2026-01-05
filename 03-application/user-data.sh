#!/usr/bin/env bash

exec > /var/log/user-data.log 2>&1
set -euxo pipefail

echo "=== User-data script started at $(date) ==="

# Update system (Amazon Linux uses dnf)
dnf update -y

# Install Docker (available in Amazon Linux repos)
dnf install -y docker

# Start and enable Docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group (optional, allows non-root docker access)
usermod -aG docker ec2-user

# Run Node Exporter
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  --network host \
  --pid host \
  -v "/:/host:ro,rslave" \
  prom/node-exporter:latest \
  --path.rootfs=/host

# Run sample web application
docker run -d \
  --name ${app_name} \
  --restart unless-stopped \
  -p ${app_port}:8080 \
  -e HOSTNAME=${app_name} \
  nginxdemos/hello:latest

echo "${app_name} deployed successfully!" > /var/log/app-setup.log

echo "=== User-data script completed at $(date) ==="