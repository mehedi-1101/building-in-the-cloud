# ─── Public EC2 Security Group ────────────────────────────────────────────────
# SSH allowed from your laptop IP only — not 0.0.0.0/0.
# my_ip must be set in terraform.tfvars (e.g. "103.195.205.20/32").

resource "aws_security_group" "public" {
  name        = "${var.owner}-public-sg"
  description = "Public EC2 - SSH from laptop only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.owner}-public-sg" }
}

# ─── Private EC2 Security Group ───────────────────────────────────────────────
# SSH allowed only from the public SG — SG reference, not a CIDR.
# This stays correct even if the public EC2 is replaced and gets a new IP.
# You cannot SSH directly from the internet — only via the bastion (public EC2).

resource "aws_security_group" "private" {
  name        = "${var.owner}-private-sg"
  description = "Private EC2 - SSH from public EC2 only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description            = "SSH from public EC2 via bastion"
    from_port              = 22
    to_port                = 22
    protocol               = "tcp"
    security_groups        = [aws_security_group.public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.owner}-private-sg" }
}
