# 03-applications/outputs.tf
output "app_public_ips" {
  description = "Public IPs of application servers"
  value       = aws_instance.app[*].public_ip
}

output "app_private_ips" {
  description = "Private IPs of application servers"
  value       = aws_instance.app[*].private_ip
}

output "app_urls" {
  description = "Application URLs"
  value       = [for ip in aws_instance.app[*].public_ip : "http://${ip}:${var.app_port}"]
}
