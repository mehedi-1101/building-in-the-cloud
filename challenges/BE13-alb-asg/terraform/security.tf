resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg-${var.owner}"
  description = "ALB — allow HTTP from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-alb-sg-${var.owner}" }
}

# EC2 SG references the ALB SG as source — not a CIDR.
# This means only traffic that passed through the ALB is allowed in.
# Stays correct as instances scale and IPs change.
resource "aws_security_group" "ec2" {
  name        = "${var.project}-ec2-sg-${var.owner}"
  description = "EC2 — allow HTTP from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-ec2-sg-${var.owner}" }
}
