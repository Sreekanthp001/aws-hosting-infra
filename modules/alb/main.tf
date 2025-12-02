resource "aws_lb" "this" {
  name               = "${replace(var.domain, ".", "-")}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.security_group_id]
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.domain}",
    "venturemond.${var.domain}",
    "sampleclient.${var.domain}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}


data "aws_route53_zone" "selected" {
  zone_id = var.hosted_zone_id
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => dvo
  }

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 300

  allow_overwrite = true

  records = [
    each.value.resource_record_value
  ]
}


resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [
    for r in aws_route53_record.validation : r.fqdn
  ]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.cert_validation.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "tg" {
  for_each = toset(var.services)

  name        = "${each.key}-${replace(var.domain, ".", "-")}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path     = "/"
    matcher  = "200-399"
    interval = 30
    timeout  = 10
  }
}

resource "aws_lb_listener_rule" "host_rules" {
  for_each = aws_lb_target_group.tg

  listener_arn = aws_lb_listener.https.arn
  priority     = 100 + index(keys(aws_lb_target_group.tg), each.key)

  action {
    type             = "forward"
    target_group_arn = each.value.arn
  }

  condition {
    host_header {
      values = [
        "${each.key}.${var.domain}",
        var.domain
      ]
    }
  }
}
