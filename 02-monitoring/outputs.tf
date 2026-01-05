# 02-monitoring/outputs.tf
output "monitoring_server_public_ip" {
  description = "Public IP of monitoring server"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_server_private_ip" {
  description = "Private IP of monitoring server"
  value       = aws_instance.monitoring.private_ip
}

output "prometheus_url" {
  description = "Prometheus UI URL"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana UI URL"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "grafana_credentials" {
  description = "Grafana default credentials"
  value       = "Username: admin, Password: admin (change after first login)"
}

output "security_group_id" {
  description = "Monitoring security group ID"
  value       = aws_security_group.monitoring.id
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i /path/to/${data.terraform_remote_state.network.outputs.key_pair_name}.pem ubuntu@${aws_instance.monitoring.public_ip}"
}
