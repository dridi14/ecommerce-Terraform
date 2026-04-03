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
