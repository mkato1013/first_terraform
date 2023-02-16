# first_terraform
[概要]
Terraformを使用して、AWSの環境構築練習のためのソース

## 事前準備(macOS)
aws-cliで、profileに、IAMユーザー登録。
本ソースコードでは、デフォルトで「terraform」というユーザーを使用。

terraformインストール

`brew install tfenv`

`tfenv install 1.3.8`

`tfenv use 1.3.8`

git-secretsのインストール

`brew install git-secrets`

git-secrets初期化

`git secrets --register-aws --global`

`git secrets --install ~/.git-templates/git-secrets -f`

`git config --global init.templatedir ~/.git-templates/git-secrets`
## 手順
ワークスペースを初期化

`terraform init`

実行計画の参照

`terraform plan`

リソース作成

`terraform apply`
`yes`
- こっちでもいい

`terraform apply --auto-approve`
## プロバイダ関連
`main.tf`
## VPC関連
`network.tf`

### サブネット
1a,1cでそれぞれpublicとprivateを作成。

- public 1a "192.168.1.0/24"
- public 1c "192.168.2.0/24"
- private 1a "192.168.3.0/24"
- private 1c "192.168.4.0/24"

### ルートテーブル
publicとprivate用の2つ作成。

### インターネットゲートウェイ
VPCへインターネットゲートウェイの設定

publicのルートテーブルと接続する

## セキュリティグループ
### 以下の4つ作成
- WEB
    - HTTP、HTTPSが入る
    - TCP3000が出る
- AP
    - TCP3000が入る
    - HTTP,HTTPSがS3へ出るのとMYSQL向けポートTCP3306が出る
- DB
    - MYSQL向けのポート TPC3306が入る
- 運用管理
    - SSH、TCP3000が入る
    - HTTP、HTTPSが出る

## プレフィックスリスト
外部から取り込む系は以下ファイルに定義

`data.tf`

## RDS
`rds.tf`

- マルチAZは未使用

### DB削除方法
以下に編集
```
  # deletion_protection = true
  # skip_final_snapshot = false
  deletion_protection = false
  skip_final_snapshot = true
```

`terraform plan`

`terraform apply --auto-approve`

その後

`resource "aws_db_instance" "mysql_standalone" {...}`

をコメントアウトし、

`terraform plan`

`terraform apply --auto-approve`

再度作成する際は、逆の方法。

## AMI
外部から情報を取得してくるため、

`data.tf`

## キーペア
事前に、公開鍵秘密鍵を作成する。ローカルで以下のコマンド。

`ssh-keygen -t rsa -b 2048 -f 鍵の名前`

srcディレクトリ内に、作成したファイルを移動。

`appserver.tf`

に記載。

## EC2
`appserver.tf`

## S3
terraform管理外でコンソール上から、バケットを作成。
ポリシーは非公開で、指定のIAMユーザー（デフォルトだとterraform）のみすべて許可するように設定する。

`main.tf`

設定する際、

`terraform init`

で初期化する。

## IAM
`iam.tf`

SessionManager、S3、EC2、Parameter storeをIAMロールへ接続。

## Parameter store
`appserver.tf`

DBの `ホスト` `ポート` `DB名` `ユーザー名` `パスワード` を保存。