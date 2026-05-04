# ─── Elastic IP ───────────────────────────────────────────────────────────────
# Static public IP for the NAT Gateway.
# The internet sees all outbound traffic from private instances as coming from this IP.
# COST: free while attached to running NAT GW. Charged ~$0.005/hr if unattached.

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "${var.owner}-nat-eip" }
}

# ─── NAT Gateway ──────────────────────────────────────────────────────────────
# Must live in the PUBLIC subnet — it needs the IGW route to reach the internet.
# Private instances route outbound traffic here. NAT GW translates source IP to
# its Elastic IP before forwarding. Return traffic comes back and is forwarded
# to the originating private instance (connection tracking).
# COST: ~$0.045/hr + $0.045/GB — destroy after lab.

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id   # must be public subnet, not private

  tags = { Name = "${var.owner}-nat-gw" }

  depends_on = [aws_internet_gateway.main]
}

# ─── Private route: 0.0.0.0/0 → NAT GW ──────────────────────────────────────
# Defined separately (not inline in aws_route_table) because it depends on the
# NAT GW which is created after the route table.

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
