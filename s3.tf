resource "random_string" "s3_unique_key" {
  length  = 6
  upper   = false # 大文字未使用
  lower   = true  # 小文字使用
  numeric = true  # 数値使用（number非推奨）
  special = false # 特殊文字未使用
}

#------------------
# S3 static bucket
#------------------
resource "aws_s3_bucket" "s3_static_bucket" {
  bucket = "${var.project}-${var.environment}-static-bucket-${random_string.s3_unique_key.result}"

  # Warning対応
  # versioning {
  #   enabled = false
  # }
}

# Warning対応
resource "aws_s3_bucket_versioning" "s3_static_bucket" {
  bucket = aws_s3_bucket.s3_static_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_static_bucket" {
  bucket                  = aws_s3_bucket.s3_static_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false

  # 依存関係定義（子:aws_s3_bucket_policy）
  depends_on = [
    aws_s3_bucket_policy.s3_static_bucket
  ]
}

resource "aws_s3_bucket_policy" "s3_static_bucket" {
  bucket = aws_s3_bucket.s3_static_bucket.id
  # dataブロックから参照
  policy = data.aws_iam_policy_document.s3_static_bucket.json
}

data "aws_iam_policy_document" "s3_static_bucket" {
  statement {
    effect    = "Allow" # 誰でもアクセスできる
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_static_bucket.arn}/*"]
    principals {
      # 全ての人に対して
      type        = "*"
      identifiers = ["*"]
    }
  }
}

#------------------
# S3 deploy bucket（オートスケールした際にとってくるソースの保管場所）
#------------------
resource "aws_s3_bucket" "s3_deploy_bucket" {
  bucket = "${var.project}-${var.environment}-deploy-bucket-${random_string.s3_unique_key.result}"

  # Warning対応
  # versioning {
  #   enabled = false
  # }
}
# Warning対応
resource "aws_s3_bucket_versioning" "s3_deploy_bucket" {
  bucket = aws_s3_bucket.s3_deploy_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_deploy_bucket" {
  bucket                  = aws_s3_bucket.s3_deploy_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true # privateなものだから拒否

  # 依存関係定義（子:aws_s3_bucket_policy）
  depends_on = [
    aws_s3_bucket_policy.s3_deploy_bucket
  ]
}

resource "aws_s3_bucket_policy" "s3_deploy_bucket" {
  bucket = aws_s3_bucket.s3_deploy_bucket.id
  # dataブロックから参照
  policy = data.aws_iam_policy_document.s3_deploy_bucket.json
}

data "aws_iam_policy_document" "s3_deploy_bucket" {
  statement {
    effect    = "Allow" # 誰でもアクセスできる
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_deploy_bucket.arn}/*"]
    principals {
      # privateなのでアクセス制限をかける
      type        = "AWS"
      identifiers = [aws_iam_role.app_iam_role.arn] # APサーバー用のIAMrole
    }
  }
}