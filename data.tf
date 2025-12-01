data "aws_route53_zone" "primary" {
  name = "venturemond.site"
  private_zone = false
}