# RaiseTech AWS Labs

RaiseTechのAWS課題を通じて取り組んだ、インフラ構築・設定・動作検証の学習記録です。

AWSの各種サービスやInfrastructure as Code（IaC）の理解を深めることを目的としています。

## 1. 実装概要

CloudFormationを使用し、Spring Bootアプリケーションを実行するAWSインフラ環境を構築しました。

主な構成は以下のとおりです。

- **VPC**：Public / Private Subnetを2つのAZに配置
- **EC2**：Amazon Linux 2023、Java 21、Spring Boot
- **RDS**：MySQL（Single-AZ）
- **ALB**：インターネットからのHTTPアクセスをEC2の8080番ポートへ転送
- **Security Group**：各リソース間の通信制御
- **Secrets Manager**：RDSの認証情報を自動管理
- **systemd**：Spring Bootアプリケーションのサービス管理・自動起動

なお、ALBは複数AZを使用していますが、EC2とRDSはそれぞれ1台の構成です。

## 2. ディレクトリ構成

| ファイル | 内容 |
|---|---|
| `cloudformation/templates/network.yaml` | VPC、Subnet、IGW、Route Table |
| `cloudformation/templates/security.yaml` | ALB・EC2・RDSのSecurity Group |
| `cloudformation/templates/database.yaml` | RDS、DB Subnet Group、Secrets Manager連携 |
| `cloudformation/templates/application.yaml` | EC2、ALB、Target Group、Listener、IAM、User Data |

## 3. CloudFormationスタックの構築手順

CloudFormationのスタックを機能ごとに分割し、`Outputs` / `Export` と `Fn::ImportValue` を使用して連携させています。

### スタックの作成順序

1. `network`
2. `security`
3. `database`
4. `application`

### スタック名・Export名の運用ルール

各スタックのExport名は、`スタック名-出力名` の形式で定義しています。

例：

- `network-VpcId`
- `network-PublicSubnetAId`
- `network-PrivateSubnetAId`
- `security-InstanceSecurityGroupId`
- `security-RDSSecurityGroupId`
- `database-RdsEndpoint`
- `database-RdsSecretArn`

各テンプレートでは、これらのExport名を `Fn::ImportValue` で参照しています。

そのため、スタック作成時は上記のスタック名を使用してください。

また、スタック間でExport値を参照するため、同じAWSアカウント・リージョン内で構築する必要があります。

### 構築時の注意事項

- Securityスタックの `MyIP` パラメータには、SSH接続元のグローバルIPv4アドレスをCIDR形式（`/32`）で指定してください。
- EC2接続用のキーペアを事前に準備してください。
- Amazon Linux 2023のAMIは、SSMパブリックパラメータを利用して取得します。
- RDSのマスターパスワードはSecrets Managerで自動管理し、EC2のIAMロールを使用して取得します。
- パスワードや秘密鍵などの機密情報はGitHubに保存しないでください。

### Securityスタックのデプロイ例（AWS CLI）

以下は、SSH接続元IPアドレスを指定してSecurityスタックを作成・更新する例です。

```bash
aws cloudformation deploy \
  --stack-name security \
  --template-file cloudformation/templates/security.yaml \
  --parameter-overrides MyIP=203.0.113.10/32 \
  --region ap-northeast-1
```

`203.0.113.10/32` は説明用のIPアドレスです。実行する際は、自分の接続元グローバルIPv4アドレスに置き換えてください。

なお、このコマンドは `network` スタックの作成後に実行します。

## 4. 動作確認

以下の項目について動作確認を実施しました。

- CloudFormationによるスタックの作成
- User Dataによるアプリケーションの自動セットアップ
- systemdによるSpring Bootの起動と自動起動設定
- EC2再起動後のアプリケーション起動
- Spring BootからRDSへの接続・データ取得
- EC2上でのHTTP 200レスポンス
- ALB経由でのアプリケーション表示
- Secrets Managerへの移行後の再構築・動作確認
- EC2の置換後の動作確認

## 5. 今後の学習予定

- CloudWatch Logsによるログ収集・監視
- AWS WAFによるWebアプリケーションの保護
- CloudFormationのNested Stacksによる構築
- 構築・運用手順の改善

## 6. 注意事項

本リポジトリは学習を目的としたものです。

AWSリソースの作成・稼働には料金が発生する場合があります。検証後は不要なリソースを削除し、課金状況を確認してください。

RDSなどのリソースは削除時の設定によってデータが失われる場合があるため、必要なデータは事前にバックアップしてください。
