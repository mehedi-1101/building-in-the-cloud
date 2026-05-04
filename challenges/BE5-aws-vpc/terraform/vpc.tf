# ─── VPC ──────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = { Name = "${var.owner}-vpc" }
}

# ─── Subnets ──────────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true   # instances get public IPs automatically

  tags = { Name = "${var.owner}-public-subnet" }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false  # no public IPs — private instances only

  tags = { Name = "${var.owner}-private-subnet" }
}

# ─── Internet Gateway ──────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.owner}-igw" }
}

# ─── Public Route Table ────────────────────────────────────────────────────────
# Dedicated RT for the public subnet — never use the main RT for this.
# Putting IGW route in the main RT would make every new subnet accidentally public.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.owner}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─── Private Route Table ──────────────────────────────────────────────────────
# Dedicated RT for the private subnet.
# NAT route (0.0.0.0/0 → NAT GW) is added in nat.tf after NAT GW is created.
# Peering route (10.1.0.0/16 → pcx) is added in peering.tf.

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.owner}-private-rt" }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
