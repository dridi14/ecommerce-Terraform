terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "deployment" {
  count   = var.target_base_url == null && var.deployment_state_file_path != null ? 1 : 0
  backend = "local"

  config = {
    path = var.deployment_state_file_path
  }
}

locals {
  target_base_url_effective = coalesce(
    var.target_base_url,
    try(data.terraform_remote_state.deployment[0].outputs[var.deployment_url_output_name], null)
  )
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_security_group" "load_test" {
  name        = "${var.project_name}-load-test-sg"
  description = "Allow SSH access for load test instance"
  vpc_id      = data.aws_subnet.selected.vpc_id

  ingress {
    description = "SSH from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-load-test-sg"
  }
}

resource "aws_instance" "load_test" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.load_test.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data                   = file("${path.module}/user_data.sh")

  tags = {
    Name = "${var.project_name}-load-test"
  }
}

resource "null_resource" "copy_storefront_script" {
  depends_on = [aws_instance.load_test]

  triggers = {
    instance_id     = aws_instance.load_test.id
    local_file_hash = filemd5(var.k6_script_local_path)
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = aws_instance.load_test.public_ip
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = var.k6_script_local_path
    destination = "/home/ubuntu/storefront.js"
  }
}

resource "null_resource" "run_k6" {
  count      = var.auto_run_k6 ? 1 : 0
  depends_on = [null_resource.copy_storefront_script]

  triggers = {
    instance_id     = aws_instance.load_test.id
    target_base_url = local.target_base_url_effective
    script_hash     = filemd5(var.k6_script_local_path)
  }

  lifecycle {
    precondition {
      condition     = local.target_base_url_effective != null && local.target_base_url_effective != ""
      error_message = "No target URL found. Set target_base_url or configure deployment_state_file_path + deployment_url_output_name."
    }
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = aws_instance.load_test.public_ip
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/load-tests",
      "sudo mv /home/ubuntu/storefront.js /opt/load-tests/storefront.js",
      "cd /opt/load-tests",
      "k6 run -e BASE_URL=${local.target_base_url_effective} storefront.js"
    ]
  }
}
