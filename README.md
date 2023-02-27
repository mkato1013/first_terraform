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

アプリケーションのソースコードは用意しておく。

## 注意点
APサーバーのOSの選択・起動、ミドルウェアのインストール、アプリケーションの設計は、省略。

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

## S3（terraform管理外）
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

## ALB
`elb.tf`

## Route53
`route53.tf`

ドメインは、お名前.comから取得。

ドメインの設定から、ネームサーバーを4つ登録する。

## ACM(Certificate)
`acm.tf`

acm.tfを削除した際、関連するリソース（ここではroute53）も削除できた方が綺麗だから、
敢えてroute53のレコードを、acm.tfへ記述。

CNAME作成後、お名前.comにてCNAMEレコードを登録する

別途、 `main.tf` に `バージニア` を記載。

## S3
`s3.tf`

`サイト用`、オートスケール等で使用する`デプロイ用`の2つ。

- `latest` - アプリケーションの管理version
- `tar.gz` - アプリケーションのソースをtarに固める

## オートスケール
`appserver.tf` の `launch template` にて設定。

初期化スクリプトは、 `src/initialize.sh`
- `appserver.tf` に初期化スクリプトを登録。
- S3に、tarで固めたソースを置いておく必要あり
- 適宜スクリプトファイルは修正。ディレクトリ、バケット名など。

EC2インスタンスからAMIイメージを作成し、Amazon linuxから作成したAMIにイメージを変更していく。

### AMIイメージに変更後
- data.tfの「aws_ami」でamazon linuxの箇所をコメントアウトし、新たに、AMIイメージ用のfilterを追加
- appserver.tfのEC2インスタンスをコメントアウト
- elb.tfの「aws_lb_target_group_attachment」をコメントアウト


実行後は、EC2の起動テンプレートが作成され、そこからインスタンスの起動を行う。
（コンソール上にて実行）
