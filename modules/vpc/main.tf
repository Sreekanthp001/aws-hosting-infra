data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Total number of subnets needed across AZs
  expected_subnets = max(var.public_subnet_count, var.private_subnet_count)

  # If user passed AZs, use them
  # Otherwise pick from available AZs
  azs = (
    length(var.availability_zones) > 0
    ? var.availability_zones
    : slice(
        data.aws_availability_zones.available.names,
        0,
        local.expected_subnets
      )
  )
}


resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    {
      Name = "${var.tags["Environment"]}-vpc"
    },
    var.tags
  )
}

resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.tags["Environment"]}-public-${count.index}"
    },
    var.tags
  )
}

resource "aws_subnet" "private" {
  count = var.private_subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + var.public_subnet_count)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name = "${var.tags["Environment"]}-private-${count.index}"
    },
    var.tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.tags["Environment"]}-igw"
    },
    var.tags
  )
}

resource "aws_eip" "nat" {
  count = var.public_subnet_count

  vpc = true

  tags = merge(
    {
      Name = "${var.tags["Environment"]}-nat-eip-${count.index}"
    },
    var.tags
  )
}

resource "aws_nat_gateway" "nat" {
  count = var.public_subnet_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name = "${var.tags["Environment"]}-nat-gw-${count.index}"
    },
    var.tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    {
      Name = "${var.tags["Environment"]}-public-rt"
    },
    var.tags
  )
}

resource "aws_route_table_association" "public_assoc" {
  count = var.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = var.private_subnet_count

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(
    {
      Name = "${var.tags["Environment"]}-private-rt-${count.index}"
    },
    var.tags
  )
}

resource "aws_route_table_association" "private_assoc" {
  count = var.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
