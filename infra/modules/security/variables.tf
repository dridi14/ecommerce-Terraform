variable "name_prefix" {
  description = "Prefix used for naming all security resources (e.g. project-env)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created."
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL from the EKS cluster (used for IRSA)."
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB to associate with WAF. Leave empty to skip association (ALB not yet created)."
  type        = string
  default     = ""
}

variable "waf_rate_limit_per_5min" {
  description = "Maximum number of requests allowed per IP per 5-minute window before WAF blocks."
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Tags applied to all security resources."
  type        = map(string)
  default     = {}
}

variable "enable_secrets_manager" {
  description = "Create an AWS Secrets Manager secret for application secrets."
  type        = bool
  default     = false
}

variable "app_secrets_json" {
  description = "Optional JSON payload to store in AWS Secrets Manager for the application."
  type        = string
  default     = ""
  sensitive   = true
}
