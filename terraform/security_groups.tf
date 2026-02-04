# Groupe de sécurité de l'ALB — autorise entrée HTTP (80) et HTTPS (443) depuis Internet ; sortie illimitée.
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "ALB security group"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

# Groupe de sécurité des tâches ECS — entrée uniquement depuis l'ALB sur le port du conteneur ; sortie illimitée.
resource "aws_security_group" "ecs" {
  name        = "${local.name}-ecs"
  description = "ECS tasks security group"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

# Groupe de sécurité DocumentDB — entrée MongoDB (27017) uniquement depuis les tâches ECS ; sortie illimitée.
resource "aws_security_group" "docdb" {
  name        = "${local.name}-docdb"
  description = "DocumentDB security group"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

# Groupe de sécurité Redis (ElastiCache) — entrée port 6379 uniquement depuis les tâches ECS ; sortie illimitée.
resource "aws_security_group" "redis" {
  name        = "${local.name}-redis"
  description = "Redis security group"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}
