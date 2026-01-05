# Prometheus needs read-only EC2 metadata access.
resource "aws_iam_policy" "prometheus_ec2_discovery" {
  name        = "prometheus-ec2-discovery"
  description = "Allow Prometheus to discover EC2 instances via EC2 API"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role.
resource "aws_iam_role_policy_attachment" "prometheus_ec2_discovery" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_ec2_discovery.arn
}

# This role is assumed by the EC2 instance running Prometheus.
resource "aws_iam_role" "prometheus" {
  name = "prometheus-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Instance profile to attach the role to EC2 instance.
resource "aws_iam_instance_profile" "prometheus" {
  name = "prometheus-instance-profile"
  role = aws_iam_role.prometheus.name
}

