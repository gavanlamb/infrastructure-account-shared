resource "aws_lb" "alb" {
  name = var.alb_name
  
  load_balancer_type = "application"

  subnets = module.vpc.public_subnets
  security_groups = [
    aws_security_group.alb.id]

  enable_deletion_protection = true

  tags = local.default_tags
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

  tags = merge(
    local.default_tags,
    {
      Name = "${var.alb_name}-sg"
    }
  )
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
  certificate_arn = aws_acm_certificate.expensely_io_wildcard.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No rule found to forward to a target group."
      status_code = "200"
    }
  }
}
