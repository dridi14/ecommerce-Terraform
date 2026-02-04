# Nom DNS de l'ALB — utilisé pour résoudre l'adresse du load balancer de l'application.
output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

# URL d'accès à l'application via l'ALB (HTTP, sans HTTPS).
output "alb_url" {
  value = "http://${aws_lb.app.dns_name}"
}

# Nom de domaine CloudFront — cette valeur est le point d'accès URL à notre front (médias / assets). Utiliser https://<cette_valeur> pour l'URL complète.
output "cloudfront_domain" {
  value = aws_cloudfront_distribution.media.domain_name
}

# Nom du bucket S3 utilisé pour les médias (upload utilisateur, présentation, documentation).
output "media_bucket_name" {
  value = aws_s3_bucket.media.bucket
}

# URL du dépôt ECR où l'image Docker de l'application est poussée (pour build/pull).
output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

# Nom du cluster ECS qui exécute les tâches de l'application.
output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

# Nom du service ECS de l'application (pour logs, scaling, déploiements).
output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

# Adresse du nœud primaire Redis (ElastiCache) — endpoint de connexion au cache.
output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

# Endpoint du cluster DocumentDB (si activé) — point de connexion base de données.
output "docdb_endpoint" {
  value       = var.enable_documentdb ? aws_docdb_cluster.this[0].endpoint : ""
  description = "DocumentDB endpoint (if enabled)"
}
