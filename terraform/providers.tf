# Provider AWS — région issue de var.aws_region.
provider "aws" {
  region = var.aws_region

  # Tags appliqués par défaut à toutes les ressources (Cost Explorer / FinOps) : Project, Environment, ManagedBy.
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
