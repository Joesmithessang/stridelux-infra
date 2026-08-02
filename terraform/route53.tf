#############################################
# StrideLux — route53.tf
# Existing public hosted zone (data lookup — do NOT create a new zone).
# NS and SOA records at the apex are auto-managed by Route 53 and are
# intentionally NOT defined here.
#############################################

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# ── Apex + www alias records to CloudFront ───────────────────────

resource "aws_route53_record" "apex" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

# ── ACM certificate validation ───────────────────────────────────
# Generated dynamically from the certificate's validation options so the
# record stays correct if the cert is ever reissued. Uses a managed
# aws_acm_certificate resource; if you prefer to keep the existing cert
# unmanaged, `terraform import` it or keep only the data source in
# cloudfront.tf and delete this block.

resource "aws_acm_certificate" "domain" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.strideluxstore.com"]
  validation_method         = "DNS"
  tags                      = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.domain.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 300
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "domain" {
  certificate_arn         = aws_acm_certificate.domain.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}

# ── SES DKIM records (generated from tokens, not hardcoded) ──────

resource "aws_route53_record" "ses_dkim" {
  count = 3

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 1800
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# ── DMARC ────────────────────────────────────────────────────────
# p=none is monitor-only (matches live). Consider p=quarantine or
# p=reject once DKIM/SPF alignment is confirmed stable.

resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=none;"]
}

# ── SPF (recommended addition — no SPF record exists today) ──────
# Uncomment to complete email authentication if SES is the only sender:
#
# resource "aws_route53_record" "spf" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "TXT"
#   ttl     = 300
#   records = ["v=spf1 include:amazonses.com ~all"]
# }
