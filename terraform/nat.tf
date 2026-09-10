# -------------------------
# Elastic IPs for NAT Gateways
# -------------------------

resource "aws_eip" "nat" {
  count = 2

  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-${count.index + 1}"
    Environment = var.environment
  }
}

# -------------------------
# NAT Gateways
# -------------------------

resource "aws_nat_gateway" "main" {
  count = 2

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name        = "${var.project_name}-nat-${count.index + 1}"
    Environment = var.environment
  }
}

# -------------------------
# Private App Routes
# -------------------------

resource "aws_route" "private_app_nat" {
  count = 2

  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}