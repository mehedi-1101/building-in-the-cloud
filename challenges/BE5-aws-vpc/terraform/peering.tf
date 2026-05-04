# ─── VPC Peering Connection ────────────────────────────────────────────────────
# Connects mh-vpc (requester) and mh-vpc2 (accepter).
# auto_accept works because both VPCs are in the same account and region.
# Cross-account peering requires a separate aws_vpc_peering_connection_accepter resource.

resource "aws_vpc_peering_connection" "main" {
  vpc_id      = aws_vpc.main.id
  peer_vpc_id = aws_vpc.vpc2.id
  auto_accept = true

  tags = { Name = "${var.owner}-vpc-peering" }
}

# ─── Routes — both sides required ─────────────────────────────────────────────
# The peering tunnel exists but traffic won't flow until each VPC's route table
# has an entry pointing to it. Both directions must be configured explicitly.
# Missing either side = one-way silence (ping sends, reply has no path back).

# Main VPC private subnet → vpc2
resource "aws_route" "private_to_vpc2" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = var.vpc2_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

# VPC2 → main VPC private subnet
resource "aws_route" "vpc2_to_main" {
  route_table_id            = aws_route_table.vpc2.id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}
