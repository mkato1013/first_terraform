#===================
# Certificate
#===================
resource "aws_acm_certificate" "tokyo_cert" {
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  # route53との依存関係
  depends_on = [
    aws_route53_zone.route53_zone
  ]
}

resource "aws_route53_record" "route53_acm_dns_resolve" {
  # for_eachで作成すると、aws_route53_recordも配列になる。
  for_each = {
    # for文。dvo = domain_validation_optionsの略。
    # domain_nameをkey、オブジェクトをvalue。
    for dvo in aws_acm_certificate.tokyo_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  allow_overwrite = true
  zone_id         = aws_route53_zone.route53_zone.id
  name            = each.value.name
  type            = each.value.type
  ttl             = 600
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert_valid" {
  certificate_arn = aws_acm_certificate.tokyo_cert.arn
  # Route53レコードに登録した検証用CNAMEレコードのFQDN
  # aws_route53_recordは配列のためforで展開する
  validation_record_fqdns = [for record in aws_route53_record.route53_acm_dns_resolve : record.fqdn]
}

# バージニア region  - ほぼTokyoと同じ
resource "aws_acm_certificate" "virginia_cert" {
  # providerでデフォルトを上書きできる
  provider          = aws.virginia
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  # route53との依存関係
  depends_on = [
    aws_route53_zone.route53_zone
  ]
}