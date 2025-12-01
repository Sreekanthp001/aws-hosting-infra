resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
  tags       = { Name = "${var.name}-vpc" }
}

resource "aws_subnet" "public" {
  for_each                = toset(var.public_azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, index(var.public_azs, each.key))
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each          = toset(var.private_azs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 10 + index(var.private_azs, each.key))
  availability_zone = each.key
  tags              = { Name = "${var.name}-private-${each.key}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.nat_azs) > 0 ? length(var.nat_azs) : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = length(var.nat_azs) > 0 ? aws_subnet.public[var.nat_azs[count.index]].id : element(values(aws_subnet.public), 0).id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_eip" "nat" {
  count = length(var.nat_azs) > 0 ? length(var.nat_azs) : 1
}

# Route tables: public and private with nat
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.name}-rt-public" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  tags = { Name = "${var.name}-rt-private" }
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
