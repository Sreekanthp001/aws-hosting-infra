resource "aws_lb" "alb" {
  name               = replace(var.domain, ".", "-")  # ALB name must be alphanumeric + hyphen
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb_sg.id] # ensure this SG exists
}



# Two target groups as examples; services will register with these ARNs
resource "aws_lb_target_group" "tg" {
  for_each  = { for name in ["venturemond", "sampleclient"] : name => name }
  name      = "${each.key}-${replace(var.domain, ".", "-")}"
  port      = 80
  protocol  = "HTTP"
  vpc_id    = var.vpc_id

  health_check {
    path     = "/"
    matcher  = "200-399"
    interval = 30
    timeout  = 10
  }
}

# ACM certificate request (DNS) - domain + www and wildcard optional
resource "aws_acm_certificate" "cert" {
  domain_name = var.domain
  validation_method = "DNS"
  subject_alternative_names = ["www.${var.domain}"]
  lifecycle { create_before_destroy = true }
  provider = aws
}

# Create Route53 validation records if hosted zone provided
data "aws_route53_zone" "zone" {
  zone_id = var.hosted_zone_id != "" ? var.hosted_zone_id : null
  name = var.domain
  private_zone = false
  # If hosted_zone_id is empty, Terraform will try to find by name
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => dvo
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 300
  records = [each.value.resource_record_value]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}

# Listener and default rule
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action { 
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }

  depends_on = [aws_acm_certificate_validation.cert_validation]
}


# Listener rules for host-based routing
resource "aws_lb_listener_rule" "rules" {
  for_each = {
    "venturemond" = ["venturemond.${var.domain}", var.domain]
    "sampleclient" = ["sampleclient.${var.domain}"]
  }

  listener_arn = aws_lb_listener.https.arn
  priority     = 100 + index(keys({for k,v in aws_lb_target_group.tg: k=>v}), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }

  condition {
    host_header {
      values = each.value
    }
  }
}
