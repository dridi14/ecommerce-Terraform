variable "aws_region" {
  description = "AWS region for the load test infrastructure"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "For load testing"
  type        = string
  default     = "ecommerce-loadtest"
}

variable "instance_type" {
  description = "EC2 instance type used for k6 load tests"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
}

variable "private_key_path" {
  description = "Path to local private key file matching key_name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the load test resources will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the load test EC2 instance will be deployed"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "Public IP allowed to SSH to the instance (CIDR /32 recommended)"
  type        = string
}

variable "target_base_url" {
  description = "Base URL of the deployed AWS site to test. If null, it will be read from deployment terraform state output."
  type        = string
  default     = null
  nullable    = true
}

variable "deployment_state_file_path" {
  description = "Path to the terraform state file of the deployment stack that exposes the site URL output"
  type        = string
  default     = null
  nullable    = true
}

variable "deployment_url_output_name" {
  description = "Output name in deployment state that contains the target site URL"
  type        = string
  default     = "site_url"
}

variable "k6_script_local_path" {
  description = "Local path to the k6 test script that will be copied to EC2"
  type        = string
  default     = "../../load-test/storefront.js"
}

variable "auto_run_k6" {
  description = "Run k6 automatically during terraform apply"
  type        = bool
  default     = false
}
