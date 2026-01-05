#!/usr/bin/env bash

exec > /var/log/user-data.log 2>&1
set -euxo pipefail

echo "=== User-data script started at $(date) ==="
# Set hostname
hostnamectl set-hostname ${server_name}
echo "Hostname set to: ${server_name}"

### 1. System prep
dnf update -y
dnf install -y podman podman-systemd

systemctl enable podman.socket

### 2. Directories
mkdir -p /opt/monitoring/prometheus
mkdir -p /opt/monitoring/grafana/provisioning/datasources
mkdir -p /etc/containers/systemd

### 3. Prometheus config
cat > /opt/monitoring/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']
  - job_name: ec2-nodes
    ec2_sd_configs:
      - region: eu-west-2
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance_ip

      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name

      - source_labels: [__meta_ec2_tag_Environment]
        target_label: environment

      - source_labels: [__meta_ec2_instance_state]
        regex: running
        action: keep
EOF

### 4. Grafana datasource provisioning
cat > /opt/monitoring/grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

### 5. Podman network & volumes
podman network create monitoring || true
podman volume create prometheus-data || true
podman volume create grafana-data || true

### 6. Prometheus Quadlet
cat > /etc/containers/systemd/prometheus.container <<'EOF'
[Unit]
Description=Prometheus
After=network-online.target
Wants=network-online.target

[Container]
Image=docker.io/prom/prometheus:latest
ContainerName=prometheus
Network=monitoring
PublishPort=9090:9090
Volume=/opt/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
Volume=prometheus-data:/prometheus
Exec=--config.file=/etc/prometheus/prometheus.yml
Exec=--storage.tsdb.path=/prometheus
Exec=--storage.tsdb.retention.time=30d
Restart=always

[Install]
WantedBy=multi-user.target
EOF

### 7. Node Exporter Quadlet
cat > /etc/containers/systemd/node-exporter.container <<'EOF'
[Unit]
Description=Node Exporter
After=network-online.target

[Container]
Image=docker.io/prom/node-exporter:latest
ContainerName=node-exporter
Network=monitoring
PublishPort=9100:9100
Volume=/:/host:ro,rslave
Exec=--path.rootfs=/host
Restart=always

[Install]
WantedBy=multi-user.target
EOF

### 8. Grafana Quadlet
cat > /etc/containers/systemd/grafana.container <<'EOF'
[Unit]
Description=Grafana
After=prometheus.service
Requires=prometheus.service

[Container]
Image=docker.io/grafana/grafana:latest
ContainerName=grafana
Network=monitoring
PublishPort=3000:3000
Environment=GF_SECURITY_ADMIN_PASSWORD=admin
Environment=GF_USERS_ALLOW_SIGN_UP=false
Volume=grafana-data:/var/lib/grafana
Volume=/opt/monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
Restart=always

[Install]
WantedBy=multi-user.target
EOF

### 9. systemd reload & enable
systemctl daemon-reexec
systemctl daemon-reload

systemctl enable prometheus.service
systemctl enable node-exporter.service
systemctl enable grafana.service

systemctl start prometheus.service
systemctl start node-exporter.service
systemctl start grafana.service

sudo podman ps -a

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token"  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)


echo "Monitoring stack deployed successfully!" > /var/log/monitoring-setup.log
echo "Prometheus: http://$IP:9090" >> /var/log/monitoring-setup.log
echo "Grafana: http://$IP:3000" >> /var/log/monitoring-setup.log
echo "=== User-data script completed at $(date) ==="
