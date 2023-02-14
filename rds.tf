#------------------
# RDS parameter group（その他DBオプション設定）
#------------------
resource "aws_db_parameter_group" "mysql_standalone_parametergroup" {
  name   = "${var.project}-${var.environment}-mysql-standalone-parametergroup"
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

#------------------
# RDS parameter group（その他DBオプション設定）
#------------------
resource "aws_db_option_group" "mysql_standalone_optiongroup" {
  name                 = "${var.project}-${var.environment}-mysql-standalone-optiongroup"
  engine_name          = "mysql"
  major_engine_version = "8.0"
}

#------------------
# RDS subnet group
#------------------
resource "aws_db_subnet_group" "mysql_standalone_subnetgroup" {
  name = "${var.project}-${var.environment}-mysql-standalone-subnetgroup"
  subnet_ids = [
    # network.tfから参照。配列だから「,」必要。
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1c.id
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone-subnetgroup"
    Project = var.project
    Env     = var.environment
  }
}

#------------------
# RDS Instance
#------------------
resource "random_string" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "mysql_standalone" {
  engine         = "mysql"
  engine_version = "8.0.32"

  identifier = "${var.project}-${var.environment}-mysql-standalone"

  username = "admin"
  # resultで結果を参照。公式確認。
  password = random_string.db_password.result

  instance_class = "db.t2.micro"
  # デフォルトストレージ
  allocated_storage = 20
  # 拡張上限
  max_allocated_storage = 50
  storage_type          = "gp2"
  storage_encrypted     = false

  multi_az = false
  # マルチAZは使用しないためAZを指定
  availability_zone      = "ap-northeast-1a"
  db_subnet_group_name   = aws_db_subnet_group.mysql_standalone_subnetgroup.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  # publicでアクセスしない
  publicly_accessible = false
  port                = 3306

  # DBの設定周り
  name                 = "tastylog"
  parameter_group_name = aws_db_parameter_group.mysql_standalone_parametergroup.name
  option_group_name    = aws_db_option_group.mysql_standalone_optiongroup.name

  # バックアップ設定
  backup_window = "04:00-05:00"
  # 何日分保管
  backup_retention_period = 7
  # メンテナンス設定(バックアップ時間よりも後に実行)
  maintenance_window         = "Mon:05:00-Mon:08:00"
  auto_minor_version_upgrade = false

  # 自動削除させない設定(trueは自動削除しない)
  deletion_protection = true
  skip_final_snapshot = false

  # すぐ作成するかどうか
  apply_immediately = true

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone"
    Project = var.project
    Env     = var.environment
  }
}
-