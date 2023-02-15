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
# EC2 Instance
#===================
resource "aws_instance" "app_server" {
  # data.tf参照
  ami           = data.aws_ami.app.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_1a.id
  # publicIPを設定
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app_sg.id, aws_security_group.opmng_sg.id]
  key_name                    = aws_key_pair.keypair.key_name
  tags = {
    Name    = "${var.project}-${var.environment}-app-ec2"
    Project = var.project
    Env     = var.environment
    # アプリケーションサーバー
    Type = "app"
  }
}