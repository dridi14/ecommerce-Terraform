# ── Security Groups ──────────────────────────────────────────────────────────

output "alb_sg_id" {
  description = "Security Group ID for the internet-facing ALB."
  value       = aws_security_group.alb.id
}

output "eks_nodes_sg_id" {
  description = "Additional Security Group ID for EKS worker nodes."
  value       = aws_security_group.eks_nodes.id
}

output "docdb_sg_id" {
  description = "Security Group ID for DocumentDB / MongoDB."
  value       = aws_security_group.docdb.id
}

# ── WAF ───────────────────────────────────────────────────────────────────────

output "waf_web_acl_arn" {
  description = "ARN of the WAFv2 WebACL (use this to associate with additional ALBs or CloudFront)."
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_id" {
  description = "ID of the WAFv2 WebACL."
  value       = aws_wafv2_web_acl.main.id
}

# ── IAM / IRSA ───────────────────────────────────────────────────────────────

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC Identity Provider (used by IRSA)."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "alb_controller_role_arn" {
  description = "IAM Role ARN for the AWS Load Balancer Controller (annotate the K8s SA with this)."
  value       = aws_iam_role.alb_controller.arn
}

output "cluster_autoscaler_role_arn" {
  description = "IAM Role ARN for the Cluster Autoscaler (annotate the K8s SA with this)."
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "external_dns_role_arn" {
  description = "IAM Role ARN for External DNS (annotate the K8s SA with this)."
  value       = aws_iam_role.external_dns.arn
}

output "app_secret_arn" {
  description = "ARN of the optional AWS Secrets Manager secret for application secrets."
  value       = try(aws_secretsmanager_secret.app[0].arn, null)
}

output "app_secrets_read_policy_arn" {
  description = "ARN of the optional IAM policy that allows read-only access to the app secret."
  value       = try(aws_iam_policy.app_secrets_read[0].arn, null)
}
