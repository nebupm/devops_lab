# Get account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Construct bucket name (same pattern as bootstrap)
locals {
  state_bucket_name = "${var.state_bucket_prefix}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  hostname          = "monitoring-server"
}

# Read network outputs from remote state
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = local.state_bucket_name
    key    = "network/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

data "aws_ami" "amalin_latest" {
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


resource "aws_security_group" "monitoring" {
  name        = "${data.terraform_remote_state.network.outputs.environment}-monitoring-sg"
  description = "Security group for monitoring services"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.allowed_ssh_cidr]
    description = "SSH access"
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.allowed_ssh_cidr]
    description = "Prometheus UI"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.allowed_ssh_cidr]
    description = "Grafana UI"
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
    description = "Node Exporter from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${data.terraform_remote_state.network.outputs.environment}-monitoring-sg"
    Environment = data.terraform_remote_state.network.outputs.environment
  }
}

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.amalin_latest.id
  instance_type          = var.instance_type
  key_name               = data.terraform_remote_state.network.outputs.key_pair_name
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  subnet_id              = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.prometheus.name


  user_data = templatefile("${path.module}/user-data.sh", {
    environment = data.terraform_remote_state.network.outputs.environment
    aws_region  = data.terraform_remote_state.network.outputs.aws_region
    server_name = local.hostname
  })
  user_data_replace_on_change = true


  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name        = "${data.terraform_remote_state.network.outputs.environment}-monitoring-server"
    Environment = data.terraform_remote_state.network.outputs.environment
    Role        = "monitoring"
  }
}
