#===================
# key pair
#===================
resource "aws_key_pair" "keypair" {
  key_name = "${var.project}-${var.environment}-keypair"
  # 公開鍵をfileとして読みこむ
  public_key = file("./src/tastylog-dev-keypair.pub")

  tags = {
    Name    = "${var.project}-${var.environment}-keypair"
    Project = var.project
    Env     = var.environment
  }
}

#===================
# SSM Parameter Store
#===================
# 「terraform state show aws_db_instance.mysql_standalone」でDBの情報を確認する
resource "aws_ssm_parameter" "host" {
  name = "/${var.project}/${var.environment}/app/MYSQL_HOST"
  type = "String"
  # RDSのDBのホスト
  value = aws_db_instance.mysql_standalone.address
}

resource "aws_ssm_parameter" "port" {
  name = "/${var.project}/${var.environment}/app/MYSQL_PORT"
  type = "String"
  # RDSのDBのポート
  value = aws_db_instance.mysql_standalone.port
}

resource "aws_ssm_parameter" "database" {
  name = "/${var.project}/${var.environment}/app/MYSQL_DATABASE"
  type = "String"
  # RDSのDBのDB名
  value = aws_db_instance.mysql_standalone.name
}

resource "aws_ssm_parameter" "username" {
  name = "/${var.project}/${var.environment}/app/MYSQL_USERNAME"
  type = "SecureString"
  # RDSのDBのユーザー名
  value = aws_db_instance.mysql_standalone.username
}

resource "aws_ssm_parameter" "password" {
  name = "/${var.project}/${var.environment}/app/MYSQL_PASSWORD"
  type = "SecureString"
  # RDSのDBのユーザー名
  value = aws_db_instance.mysql_standalone.password
}

#===================
# EC2 Instance（amazonからAMIイメージを選択したことに伴いコメントアウト）
#===================
# resource "aws_instance" "app_server" {
#   # data.tf参照
#   ami           = data.aws_ami.app.id
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.public_subnet_1a.id
#   # publicIPを設定
#   associate_public_ip_address = true
#   # IAMロールと接続
#   iam_instance_profile = aws_iam_instance_profile.app_ec2_profile.name

#   vpc_security_group_ids = [
#     aws_security_group.app_sg.id,
#     aws_security_group.opmng_sg.id
#   ]
#   key_name = aws_key_pair.keypair.key_name
#   tags = {
#     Name    = "${var.project}-${var.environment}-app-ec2"
#     Project = var.project
#     Env     = var.environment
#     # アプリケーションサーバー
#     Type = "app"
#   }
# }

#===================
# launch template
#===================
resource "aws_launch_template" "app_lt" {
  update_default_version = true // 自動でアップデート

  name = "${var.project}-${var.environment}-app-lt"

  image_id = data.aws_ami.app.id

  key_name = aws_key_pair.keypair.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project}-${var.environment}-app-ec2"
      Project = var.project
      Env     = var.environment
      Type    = "app"
    }
  }

  network_interfaces {
    // publicIP使用可
    associate_public_ip_address = true
    security_groups = [
      aws_security_group.app_sg.id,
      aws_security_group.opmng_sg.id
    ]

    // ec2が終了後、ネットワークのリソースも合わせて削除
    delete_on_termination = true
  }
  iam_instance_profile {
    // role
    name = aws_iam_instance_profile.app_ec2_profile.name
  }
  // 初期化スクリプト
  user_data = filebase64("./src/initialize.sh")
}

#===================
# auto scaling group
#===================
resource "aws_autoscaling_group" "app_asg" {
  name = "${var.project}-${var.environment}-app-asg"

  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  health_check_grace_period = 300
  health_check_type         = "ELB"

  vpc_zone_identifier = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1c.id
  ]

  target_group_arns = [aws_lb_target_group.alb_target_group.arn]

  mixed_instances_policy {
    # 起動テンプレート
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app_lt.id
        version            = "$Latest"
      }
      override {
        # 起動テンプレートで設定していないものを追加設定
        instance_type = "t2.micro"
      }
    }
  }
}