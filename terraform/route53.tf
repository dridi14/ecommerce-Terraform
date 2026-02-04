# Enregistrement A (alias) pointant le domaine principal vers l'ALB — actif si zone_id et domain_name sont renseignés.
resource "aws_route53_record" "alb" {
  count   = var.route53_zone_id != "" && var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

# Enregistrement A (alias) pointant un sous-domaine vers CloudFront (médias) — actif si zone_id et cloudfront_domain_aliases sont renseignés.
resource "aws_route53_record" "cloudfront" {
  count   = var.route53_zone_id != "" && length(var.cloudfront_domain_aliases) > 0 ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.cloudfront_domain_aliases[0]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.media.domain_name
    zone_id                = aws_cloudfront_distribution.media.hosted_zone_id
    evaluate_target_health = false
  }
}
