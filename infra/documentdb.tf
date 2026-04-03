resource "aws_security_group" "docdb" {
  count = var.docdb_enabled ? 1 : 0

  name        = "${var.project_name}-${var.env}-docdb-sg"
  description = "DocumentDB access from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "MongoDB from VPC"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.env}-docdb-sg"
  })
}

resource "aws_docdb_subnet_group" "this" {
  count = var.docdb_enabled ? 1 : 0

  name       = "${var.project_name}-${var.env}-docdb-subnets"
  subnet_ids = module.vpc.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.env}-docdb-subnets"
  })
}

resource "aws_docdb_cluster" "this" {
  count = var.docdb_enabled ? 1 : 0

  cluster_identifier      = "${var.project_name}-${var.env}-docdb"
  engine                  = "docdb"
  master_username         = var.docdb_username
  master_password         = var.docdb_password
  db_subnet_group_name    = aws_docdb_subnet_group.this[0].name
  vpc_security_group_ids  = [aws_security_group.docdb[0].id]
  backup_retention_period = var.docdb_backup_retention_days
  skip_final_snapshot     = var.docdb_skip_final_snapshot

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.env}-docdb"
  })
}

resource "aws_docdb_cluster_instance" "this" {
  count              = var.docdb_enabled ? var.docdb_instance_count : 0
  identifier         = "${var.project_name}-${var.env}-docdb-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.this[0].id
  instance_class     = var.docdb_instance_class

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.env}-docdb-${count.index + 1}"
  })
}
