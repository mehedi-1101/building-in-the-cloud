# ─── AMI — Amazon Linux 2023 (latest, fetched dynamically) ───────────────────

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── Public EC2 ───────────────────────────────────────────────────────────────
# Lives in the public subnet — gets a public IP automatically.
# Acts as the bastion host: only entry point into the private network.
# No user data — this is a jump box, not an app server.

resource "aws_instance" "public" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.public.id]

  metadata_options {
    http_tokens                 = "required"   # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  tags = { Name = "${var.owner}-public-ec2" }
}

# ─── Private EC2 ──────────────────────────────────────────────────────────────
# Lives in the private subnet — no public IP.
# Reachable only via SSH hop through the public EC2 (bastion).
# Outbound internet via NAT GW (defined in nat.tf).

resource "aws_instance" "private" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.private.id]

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = { Name = "${var.owner}-private-ec2" }
}
