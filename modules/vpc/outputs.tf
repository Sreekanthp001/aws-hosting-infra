output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = [for s in aws_subnet.public : s.value.id]
}

output "private_subnets" {
  value = [for s in aws_subnet.private : s.value.id]
}
