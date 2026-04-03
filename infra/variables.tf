variable "project_name" {
  description = "Project name used for tagging and naming resources."
  type        = string
  default     = "black-friday-survival"
}

variable "env" {
  description = "Deployment environment (dev, preprod, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "preprod", "prod"], var.env)
    error_message = "env must be one of: dev, preprod, prod."
  }
}

variable "aws_region" {
  description = "AWS region where infrastructure is deployed."
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones used to spread subnets."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number

  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 2  
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 15
}

variable "cluster_log_retention_in_days" {
  description = "CloudWatch retention period for EKS control plane logs."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
  default     = 100
  default     = 2
}



variable "alb_arn" {
  description = <<-EOT
    ARN of the internet-facing ALB created by the AWS Load Balancer Controller.
    Leave empty on the first apply (cluster not yet running).
    Once the ALB exists, pass it with: -var='alb_arn=arn:aws:elasticloadbalancing:...'
  EOT
  type        = string
  default     = ""
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  type        = string
  default     = ""
}

variable "waf_rate_limit_per_5min" {
  description = "Max requests per IP per 5-minute window before WAF blocks. Default: 2000."
  type        = number
  default     = 2000
}

variable "alb_arn_suffix" {
  description = "The ARN suffix of the Application Load Balancer"
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "The ARN suffix of the Target Group"
  type        = string
  default     = ""
}

variable "asg_name" {
  description = "The name of the Auto Scaling Group for EKS Nodes"
  type        = string
  default     = ""
}

variable "currency" {
  description = "Currency for billing alarm"
  type        = string
  default     = "USD"
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit for billing alarm"
  type        = number
  default     = 500
}


variable "enable_secrets_manager" {
  description = "Create an AWS Secrets Manager secret for application secrets."
  type        = bool
  default     = false
}

variable "app_secrets_json" {
  description = "Optional JSON payload to store in AWS Secrets Manager for the application (for example DB credentials)."
  type        = string
  default     = ""
  sensitive   = true

# --- DocumentDB (Managed Mongo-Compatible) ---

variable "docdb_enabled" {
  description = "Whether to provision Amazon DocumentDB."
  type        = bool
  default     = true
}

variable "docdb_instance_class" {
  description = "DocumentDB instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "docdb_instance_count" {
  description = "Number of DocumentDB instances."
  type        = number
  default     = 1
}

variable "docdb_username" {
  description = "DocumentDB master username."
  type        = string
  default     = "grandnodeadmin"
}

variable "docdb_password" {
  description = "DocumentDB master password."
  type        = string
  sensitive   = true
  default     = "ChangeMeDocDBPass123"
}

variable "docdb_backup_retention_days" {
  description = "DocumentDB backup retention days."
  type        = number
  default     = 1
}

variable "docdb_skip_final_snapshot" {
  description = "Skip final snapshot on delete (dev friendly)."
  type        = bool
  default     = true

}
