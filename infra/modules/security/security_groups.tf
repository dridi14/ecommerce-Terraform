# ---------------------------------------------------------------------------
# ALB Security Group
# Allows HTTP (80) and HTTPS (443) from the public internet.
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Internet-facing ALB: allow HTTP/HTTPS inbound, all outbound."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

# ---------------------------------------------------------------------------
# EKS Nodes Security Group (additional / custom)
# Allows inbound only from the ALB SG and from peers within the node group.
# ---------------------------------------------------------------------------
resource "aws_security_group" "eks_nodes" {
  name        = "${var.name_prefix}-eks-nodes-sg"
  description = "EKS worker nodes: accept traffic from ALB and node-to-node only."
  vpc_id      = var.vpc_id

  # Traffic forwarded by the ALB to the application container port
  ingress {
    description     = "App traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # NodePort range used by Kubernetes services (optional, ALB target-type=ip bypasses this)
  ingress {
    description     = "NodePort range from ALB"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Pod-to-pod / node-to-node (same SG)
  ingress {
    description = "Node-to-node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Kubelet / metrics-server from within the same SG
  ingress {
    description = "Node-to-node UDP (VXLAN / overlay)"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    self        = true
  }

  egress {
    description = "Allow all outbound (internet access via NAT for ECR pulls, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-eks-nodes-sg" })
}

# ---------------------------------------------------------------------------
# DocumentDB / MongoDB Security Group
# Accepts connections only from EKS worker nodes on port 27017.
# ---------------------------------------------------------------------------
resource "aws_security_group" "docdb" {
  name        = "${var.name_prefix}-docdb-sg"
  description = "DocumentDB/MongoDB: inbound from EKS nodes only."
  vpc_id      = var.vpc_id

  ingress {
    description     = "MongoDB from EKS worker nodes"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  # No egress rules needed for a DB (deny-all by default is fine)
  # Adding an explicit deny-all egress for defence-in-depth
  egress {
    description = "Deny all outbound from DB tier"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["127.0.0.1/32"] # effectively blocks all egress
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-docdb-sg" })
}
