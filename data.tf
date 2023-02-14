data "aws_prefix_list" "s3_pl" {
  # 環境によってリージョンは異なるので「*」
  name = "com.amazonaws.*.s3"
}
