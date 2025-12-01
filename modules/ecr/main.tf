resource "aws_ecr_repository" "repos" {
  for_each = toset(var.repos)
  name = "${each.key}-${var.environment}"
  image_scanning_configuration { scan_on_push = true }
  image_tag_mutability = "MUTABLE"
  tags = { Environment = var.environment, Name = each.key }
}
