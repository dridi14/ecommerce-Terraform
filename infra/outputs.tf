output "vpc_id" {
  description = "ID of the created VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_oidc_issuer_url" {
  description = "EKS OIDC issuer URL."
  value       = module.eks.cluster_oidc_issuer_url
}

<<<<<<< HEAD
# ---------------------------------------------------------------------------
# Security outputs
# ---------------------------------------------------------------------------

output "alb_sg_id" {
  description = "Security Group ID for the internet-facing ALB."
  value       = module.security.alb_sg_id
}

output "eks_nodes_sg_id" {
  description = "Additional Security Group ID for EKS worker nodes."
  value       = module.security.eks_nodes_sg_id
}

output "docdb_sg_id" {
  description = "Security Group ID for DocumentDB / MongoDB."
  value       = module.security.docdb_sg_id
}

output "waf_web_acl_arn" {
  description = "WAFv2 WebACL ARN – use to associate with additional ALBs or CloudFront."
  value       = module.security.waf_web_acl_arn
}

output "oidc_provider_arn" {
  description = "EKS OIDC Identity Provider ARN."
  value       = module.security.oidc_provider_arn
}

output "alb_controller_role_arn" {
  description = "IAM Role ARN – annotate K8s SA aws-load-balancer-controller with this."
  value       = module.security.alb_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "IAM Role ARN – annotate K8s SA cluster-autoscaler with this."
  value       = module.security.cluster_autoscaler_role_arn
}

output "external_dns_role_arn" {
  description = "IAM Role ARN – annotate K8s SA external-dns with this."
  value       = module.security.external_dns_role_arn
}

output "app_secret_arn" {
  description = "AWS Secrets Manager secret ARN for application secrets."
  value       = module.security.app_secret_arn
}

output "app_secrets_read_policy_arn" {
  description = "IAM policy ARN for read-only access to the app secret."
  value       = module.security.app_secrets_read_policy_arn

output "eks_node_role_arn" {
  description = "IAM role ARN used by EKS worker nodes."
  value       = module.eks.node_role_arn
}

output "docdb_endpoint" {
  description = "DocumentDB cluster endpoint."
  value       = var.docdb_enabled ? aws_docdb_cluster.this[0].endpoint : ""
}

output "docdb_port" {
  description = "DocumentDB port."
  value       = var.docdb_enabled ? aws_docdb_cluster.this[0].port : 27017

}
