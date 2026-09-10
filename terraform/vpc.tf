data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# -------------------------
# Internet Gateway
# -------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# -------------------------
# Public Subnets
# -------------------------

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-${count.index + 1}"
    Tier        = "public"
    Environment = var.environment
  }
}

# -------------------------
# Private Application Subnets
# -------------------------

resource "aws_subnet" "private_app" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 11}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-app-${count.index + 1}"
    Tier        = "private-app"
    Environment = var.environment
  }
}

# -------------------------
# Private Database Subnets
# -------------------------

resource "aws_subnet" "private_db" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 21}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-db-${count.index + 1}"
    Tier        = "private-db"
    Environment = var.environment
  }
}

# -------------------------
# Public Route Table
# -------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Private App Route Tables
# -------------------------

resource "aws_route_table" "private_app" {
  count = 2

  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-private-app-rt-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private_app" {
  count = 2

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# -------------------------
# Private DB Route Tables
# -------------------------

resource "aws_route_table" "private_db" {
  count = 2

  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-private-db-rt-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private_db" {
  count = 2

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db[count.index].id
}