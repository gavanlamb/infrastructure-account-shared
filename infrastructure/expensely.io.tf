resource "aws_route53_zone" "expensely_io" {
  name = "${var.expensely_io_name}."
  comment = "Zone for ${var.expensely_io_name} ${var.environment}"
  tags = local.default_tags
}
module "expensely_io_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 1.0"
  count = local.create_expensely_io_route53_records ? 1 : 0
  zone_name = aws_route53_zone.expensely_io.name
  records = var.expensely_io_records
}
resource "aws_acm_certificate" "expensely_io_wildcard" {
  domain_name = "*.${var.expensely_io_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.default_tags,
    {
      Name = var.expensely_io_name
    }
  )
}

resource "aws_route53_record" "expensely_io_wildcard_validation" {
  for_each = {
  for dvo in aws_acm_certificate.expensely_io_wildcard.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = aws_route53_zone.expensely_io.zone_id
}

resource "aws_acm_certificate_validation" "expensely_io_wildcard" {
  certificate_arn         = aws_acm_certificate.expensely_io_wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.expensely_io_wildcard_validation : record.fqdn]
}
