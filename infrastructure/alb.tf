resource "aws_lb" "alb" {
  name = var.alb_name
  
  load_balancer_type = "application"

  subnets = module.vpc.public_subnets
  security_groups = [
    aws_security_group.alb.id,
    aws_security_group.external.id]

  enable_deletion_protection = true
}

resource "aws_security_group" "alb" {
  name = "${var.alb_name}-sg"
  description = "Allow all HTTP/HTTPS inbound traffic"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    description = "TLS from anywhere"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    description = "TLS from anywhere"
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Name = "${var.alb_name}-sg"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.alb.id
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.alb.id
  port = 443
  protocol = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.alb_default.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No rule found to forward to a target group."
      status_code = "200"
    }
  }
}
resource "aws_alb_listener" "test" {
  load_balancer_arn = aws_lb.alb.id
  port = 8443
  protocol = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = data.aws_acm_certificate.alb_default.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No rule found to forward to a target group."
      status_code = "200"
    }
  }
}

data "aws_acm_certificate" "alb_default" {
  domain   = var.alb_certificates[0]
  statuses = ["ISSUED"]
}

resource "aws_lb_listener_certificate" "alb" {
  count = length(var.alb_certificates)

  listener_arn = aws_alb_listener.https.arn
  certificate_arn = data.aws_acm_certificate.alb[count.index].arn
}
resource "aws_lb_listener_certificate" "alb_test" {
  count = length(var.alb_certificates)

  listener_arn = aws_alb_listener.test.arn
  certificate_arn = data.aws_acm_certificate.alb[count.index].arn
}
data "aws_acm_certificate" "alb" {
  count = length(var.alb_certificates)

  domain   = var.alb_certificates[count.index]
  statuses = ["ISSUED"]
}