data "aws_prefix_list" "s3_pl" {
  # 環境によってリージョンは異なるので「*」
  name = "com.amazonaws.*.s3"
}

data "aws_ami" "app" { # アプリケーション用だからapp
  # 最新のものを選択
  most_recent = true
  # 自分自身が登録したものと、Amazon公式のものを検索
  owners = ["self", "amazon"]

  # AMIイメージに変更後追加
  filter {
    name = "name"
    // ec2起動時に作成したAMIを使用する
    // 日付のversion管理をしていれば「*」でも有効
    values = ["tasty-*-ami"]
  }


  # # オートスケーリング実装のため、amazon linuxから作成したAMIに変更

  # filter {
  #   name = "name"
  #   # aws ec2 describe-images --image-ids インスタンスID コマンドで取得。
  #   # Name属性を記載
  #   # 途中の「日付.0」の箇所を「*」にし、全体を取得。
  #   values = ["amzn2-ami-kernel-5.10-hvm-2.0.*-x86_64-gp2"]
  # }

  # filter {
  #   name   = "root-device-type"
  #   values = ["ebs"]
  # }

  # filter {
  #   name   = "virtualization-type"
  #   values = ["hvm"]
  # }
}