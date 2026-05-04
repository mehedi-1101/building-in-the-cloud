# ─── Second VPC ───────────────────────────────────────────────────────────────
# Used for VPC peering checkpoint only.
# CIDRs must not overlap with the main VPC (10.0.0.0/16).
# No IGW, no NAT — traffic reaches it only via the peering connection.

resource "aws_vpc" "vpc2" {
  cidr_block = var.vpc2_cidr

  tags = { Name = "${var.owner}-vpc2" }
}

resource "aws_subnet" "vpc2" {
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = var.vpc2_subnet_cidr
  availability_zone = var.az

  tags = { Name = "${var.owner}-vpc2-subnet" }
}

# ─── VPC2 Route Table ─────────────────────────────────────────────────────────
# Dedicated RT for vpc2 subnet.
# Peering route (10.0.0.0/16 → pcx) is added in peering.tf after peering is created.

resource "aws_route_table" "vpc2" {
  vpc_id = aws_vpc.vpc2.id

  tags = { Name = "${var.owner}-vpc2-rt" }
}

resource "aws_route_table_association" "vpc2" {
  subnet_id      = aws_subnet.vpc2.id
  route_table_id = aws_route_table.vpc2.id
}

# ─── VPC2 Security Group ──────────────────────────────────────────────────────
# Allows ICMP (ping) and SSH from the main VPC's CIDR.
# Cannot reference the main VPC's SG across VPC boundaries — must use CIDR.

resource "aws_security_group" "vpc2" {
  name        = "${var.owner}-vpc2-sg"
  description = "VPC2 EC2 - allow ping and SSH from main VPC"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    description = "Ping from main VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "SSH from main VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.owner}-vpc2-sg" }
}

# ─── VPC2 EC2 ─────────────────────────────────────────────────────────────────
# No public IP — only reachable via peering from private EC2 in main VPC.

resource "aws_instance" "vpc2" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.vpc2.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.vpc2.id]

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = { Name = "${var.owner}-vpc2-ec2" }
}
