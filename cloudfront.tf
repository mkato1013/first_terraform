#===================
# CloudFront cache destribution
#===================
resource "aws_cloudfront_distribution" "cf" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "cache destribution" # 任意
  price_class     = "PriceClass_All"     # 基本的にこれでOK

  origin {
    domain_name = aws_route53_record.route53_record.fqdn
    origin_id   = aws_lb.alb.name # target_origin_idで使用される任意の文字列

    # 向き先がELBだからcustom_origin_config
    custom_origin_config {
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      http_port              = 80
      https_port             = 443
    }
  }

  origin {
    domain_name = aws_s3_bucket.s3_static_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.s3_static_bucket.id

    s3_origin_config {
      # どのIDで接続するか、identityの内容を記載
      origin_access_identity = aws_cloudfront_origin_access_identity.cf_s3_origin_access_identity.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"] # 受け付けるメソッド
    cached_methods  = ["GET", "HEAD"] # ELBはcacheしないが記述しておく

    # 転送時の設定
    forwarded_values {
      query_string = true
      cookies {
        forward = "all" # 転送する
      }
    }

    target_origin_id       = aws_lb.alb.name
    viewer_protocol_policy = "redirect-to-https"
    # ELBはcacheしないためcacheのttlは全て0。
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  ordered_cache_behavior {
    path_pattern    = "/public/*"
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    target_origin_id = aws_s3_bucket.s3_static_bucket.id

    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true # 圧縮
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # どのようなドメインでアクセスするか
  aliases = ["dev.${var.domain}"]

  # SSL設定
  viewer_certificate {
    # 独自のACMの証明書（バージニア）
    acm_certificate_arn      = aws_acm_certificate.virginia_cert.arn
    minimum_protocol_version = "TLSv1.2_2019" # 推奨値
    ssl_support_method       = "sni-only"     # 推奨値
  }
}

# S3へアクセスするためのidentity
resource "aws_cloudfront_origin_access_identity" "cf_s3_origin_access_identity" {
  comment = "s3 static bucket access identity"
}

resource "aws_route53_record" "route53_cloudfront" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "dev.${var.domain}"
  type    = "A"

  # どこに転送するのか
  alias {
    name                   = aws_cloudfront_distribution.cf.domain_name
    zone_id                = aws_cloudfront_distribution.cf.hosted_zone_id
    evaluate_target_health = true
  }
}

