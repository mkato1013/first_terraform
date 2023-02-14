# first_terraform
[概要]
Terraformを使用して、AWSの環境構築練習のためのソース

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
main.tf
## VPC関連
network.tf

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