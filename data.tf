data "aws_route53_zone" "primary" {
  name = "sree84s.site"
  private_zone = false
}