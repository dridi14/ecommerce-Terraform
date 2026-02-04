# Liste des zones de disponibilité (AZ) utilisables dans la région — pour répartir les subnets.
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC principal du projet — réseau isolé (CIDR configurable) avec DNS support et hostnames.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.tags
}

# Passerelle Internet attachée au VPC — permet au trafic public d'accéder à Internet.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = local.tags
}

# Subnets publics (un par AZ) — hébergent NAT Gateway, ALB ; les instances reçoivent une IP publique.
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(local.tags, {
    Tier = "public"
  })
}

# Subnets privés (un par AZ) — hébergent EKS nodes, ECS, Redis ; pas d'IP publique directe.
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(local.tags, {
    Tier = "private"
  })
}

# Adresse Elastic IP allouée pour le NAT Gateway — IP publique fixe pour la sortie Internet des subnets privés.
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = local.tags
}

# NAT Gateway — permet aux ressources des subnets privés d'accéder à Internet (outbound) sans être exposées.
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = local.tags
  depends_on    = [aws_internet_gateway.this]
}

# Table de routage des subnets publics — trafic vers 0.0.0.0/0 via l'Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = local.tags
}

# Route par défaut des subnets publics — envoie tout le trafic Internet vers l'Internet Gateway.
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Association de chaque subnet public à la table de routage publique.
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Table de routage des subnets privés — trafic vers 0.0.0.0/0 via le NAT Gateway.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = local.tags
}

# Route par défaut des subnets privés — envoie tout le trafic Internet sortant vers le NAT Gateway.
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

# Association de chaque subnet privé à la table de routage privée.
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
