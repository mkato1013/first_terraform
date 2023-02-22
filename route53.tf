#===================
# route 53
#===================
resource "aws_route53_zone" "route53_zone" {
  name          = var.domain # 購入済みのドメイン。main.tfに変数定義。tfvarsに情報記載。
  force_destroy = false

  tags = {
    Name    = "${var.project}-${var.environment}-domain"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route53_record" "route53_record" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "dev-elb.${var.domain}"
  type    = "A"
  # 向き先はALBになるため、「alias」指定
  alias {
    name    = aws_lb.alb.dns_name
    zone_id = aws_lb.alb.zone_id
    # ヘルスチェックをするか
    evaluate_target_health = true
  }
}