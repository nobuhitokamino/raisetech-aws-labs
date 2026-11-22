# Terraform - RaiseTech AWS Infrastructure

## 1. 概要

RaiseTechのAWS課題でCloudFormationを使用して構築した環境を、Terraformで再構築した学習記録です。

CloudFormationで実装したAWSインフラの構成を基本的に維持しながら、TerraformのModule、変数、Outputs、State管理、依存関係、Plan・Apply・Destroyの仕組みについて理解を深めることを目的としています。

Terraformによる環境構築後は、AWS上でアプリケーション、ネットワーク、アクセス制御、ログ収集、監視・通知の動作検証を実施しました。

また、構築時に発生したEC2のUser Dataエラーについて、Linuxのログを調査して原因を特定し、Terraformコードを修正して復旧しました。

検証終了後には、Terraformによる全リソースの削除と残存リソースの確認まで実施しています。

## 2. システム構成

### 構成概要

- **リージョン**：ap-northeast-1（東京）
- **VPC**：10.0.0.0/16
- **AZ**：2つのAvailability Zone
- **Public Subnet**：2つ
- **Private Subnet**：2つ
- **EC2**：Amazon Linux 2023、t3.micro、Java 21
- **アプリケーション**：Spring Boot、ポート8080
- **RDS**：MySQL、db.t3.micro、Single-AZ
- **ALB**：インターネット向け、HTTP:80
- **WAF**：カスタムルール、AWSマネージドルール
- **ログ**：S3、CloudWatch Logs
- **監視・通知**：CloudWatch Alarm、SNS、Dashboard

ALBは2つのAZに配置していますが、EC2とRDSはそれぞれ1台です。EC2のAuto ScalingやRDSのMulti-AZは実装していません。

### ネットワーク構成

| Subnet | CIDR | 用途 |
|---|---|---|
| Public Subnet A | 10.0.1.0/24 | EC2、ALB |
| Public Subnet C | 10.0.2.0/24 | ALB |
| Private Subnet A | 10.0.11.0/24 | RDS用DB Subnet Group |
| Private Subnet C | 10.0.12.0/24 | RDS用DB Subnet Group |

Public SubnetにはInternet Gatewayへのデフォルトルートを設定しています。

Private SubnetにはInternet Gatewayへのデフォルトルートを設定せず、RDSをインターネットから直接アクセスできない構成としています。

通信経路は次のとおりです。

```text
Client
  │
  │ HTTP : 80
  ▼
AWS WAF
  │
  ▼
Application Load Balancer
  │
  │ HTTP : 8080
  ▼
EC2 / Spring Boot
  │
  │ MySQL : 3306
  ▼
RDS MySQL
```

EC2へのSSH接続は、指定したグローバルIPv4アドレス（/32）のみに制限しています。

本構成は学習環境であり、ALBのHTTPS ListenerやEC2の冗長化などは今後の改善課題としています。

## 3. Terraformのディレクトリ構成

```text
terraform/
├── environments/
│   └── dev/
│       ├── backend.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── variables.tf
│       └── versions.tf
├── modules/
│   ├── network/
│   ├── security/
│   ├── logging/
│   ├── database/
│   ├── application/
│   ├── waf/
│   └── monitoring/
├── templates/
│   └── user_data.sh.tftpl
└── docs/
    ├── verification.md
    ├── troubleshooting.md
    └── images/
```

`docs/`以下は検証記録とスクリーンショットを整理するためのディレクトリです。

各Moduleには、基本的に以下の3ファイルを配置しています。

| ファイル | 役割 |
|---|---|
| `main.tf` | AWSリソースの定義 |
| `variables.tf` | Moduleへの入力値 |
| `outputs.tf` | 他のModuleで使用する値の出力 |

`environments/dev/main.tf`をRoot Moduleとし、7つのChild Moduleを呼び出す構成です。

## 4. Moduleの実装内容

| Module | 主な実装内容 |
|---|---|
| Network | VPC、Subnet、IGW、Route Table |
| Security | ALB・EC2・RDSのSecurity Groupと通信ルール |
| Logging | ALBアクセスログ用S3、CloudWatch Log Group |
| Database | RDS MySQL、DB Subnet Group、Secrets Manager連携 |
| Application | EC2、IAM、User Data、ALB、Target Group、Listener |
| WAF | Web ACL、カスタムルール、マネージドルール、ログ配信 |
| Monitoring | CloudWatch Alarm、SNS、Dashboard |

### Module間の値の受け渡し

各ModuleのOutputsをRoot Moduleで参照し、別のModuleの入力変数へ渡しています。

例えば、Network Moduleで作成したVPC IDをSecurity Moduleへ渡し、Security ModuleのSecurity Group IDをApplication ModuleやDatabase Moduleへ渡しています。

CloudFormationで使用していたParameters・Outputs・ImportValueに相当する連携を、Terraformでは`variable`、`output`、`module.<名前>.<出力名>`によって実装しました。

### 依存関係の管理

Terraformではリソース間の参照による暗黙的な依存関係を利用しています。

また、RDSのエラーログ用Log GroupをRDSより先に作成するため、Database ModuleにはLogging Moduleへの明示的な依存関係を設定しています。

```hcl
depends_on = [module.logging]
```

Application Moduleでも、ALBアクセスログ用S3バケットの設定が完了してからリソースを作成できるようにしています。

## 5. TerraformのバージョンとState管理

### バージョン条件

- Terraform：1.17.0以上、2.0.0未満
- AWS Provider：6.x系

`versions.tf`でTerraformおよびProviderのバージョン条件を定義しています。

### S3 Backend

Terraform Stateはローカルではなく、既存のS3 Backend用バケットに保存する構成です。

別のTerraformプロジェクトで使用しているS3バケットを共有していますが、Stateの保存先キーを分離しています。

```text
raisetech-aws-labs/dev/terraform.tfstate
```

Stateの同時更新を防ぐため、S3のネイティブロック機能である`use_lockfile = true`を使用しています。

Backend用S3バケットはTerraformの管理対象54リソースには含めていません。

**注意：** `backend.tf`のS3バケット名は使用環境に依存するため、再利用する場合は自身が利用できるBackend用バケットを事前に準備し、設定を変更する必要があります。

## 6. 構築手順

### 前提条件

- AWS CLIがインストール・認証設定済みであること
- Terraformがインストール済みであること
- 東京リージョンにEC2用キーペアを準備していること
- Terraform Backend用S3バケットを準備していること
- AWSリソースを作成するためのIAM権限があること

### 変数ファイルの準備

`terraform/environments/dev/terraform.tfvars`を作成し、環境に応じた値を設定します。

```hcl
my_ip              = "203.0.113.10/32"
ec2_key_name       = "your-key-pair-name"
notification_email = "example@example.com"
```

IPアドレス、キーペア名、メールアドレスは説明用です。

`terraform.tfvars`はGit管理対象から除外しています。

### 初期化・静的チェック

```bash
cd terraform

terraform fmt -check -recursive

cd environments/dev

terraform init

terraform validate
```

### Plan

```bash
terraform plan -out=dev.tfplan
```

保存したPlanを確認します。

```bash
terraform show dev.tfplan
```

初回構築時の結果は次のとおりです。

```text
Plan: 54 to add, 0 to change, 0 to destroy.
```

### Apply

```bash
terraform apply dev.tfplan
```

初回構築時の結果：

```text
Apply complete! Resources: 54 added, 0 changed, 0 destroyed.
```

構築後は、OutputからALBのDNS名などを確認できます。

```bash
terraform output
```

SNSのメール通知を使用するためには、届いた確認メールから購読を承認する必要があります。

## 7. セキュリティ・ログ収集・監視

### 認証情報の管理

RDSのマスターパスワードは、Secrets Managerで自動管理しています。

EC2にはIAM RoleとInstance Profileを設定し、必要なSecretを取得するための権限を付与しています。

Spring Bootの起動時にはSecrets Managerからデータベースの認証情報を取得する構成です。

### AWS WAF

以下の2種類のルールを設定しています。

| ルール | 内容 |
|---|---|
| BlockTestHeader | `x-raisetech-test: block-me`に一致するリクエストを遮断 |
| AWSManagedRulesCommonRuleSet | AWSマネージドルールによる一般的なWeb攻撃への対策 |

WAFのログはCloudWatch Logsへ転送しています。

ログではクエリ文字列、Authorizationヘッダー、Cookieヘッダーの秘匿化を設定しています。

### ログ収集

| ログ | 保存先 | 保持期間 |
|---|---|---|
| ALBアクセスログ | S3 | 14日 |
| Spring Bootアプリケーションログ | CloudWatch Logs | 14日 |
| WAFログ | CloudWatch Logs | 14日 |
| RDSエラーログ | CloudWatch Logs | 14日 |

Spring BootのログはCloudWatch Agentを使用してjournaldから収集しています。

### CloudWatch Alarm

以下の5種類のアラームを作成しました。

| アラーム | 監視内容 |
|---|---|
| ALB 5XX | ALBが生成するHTTP 5XXエラー |
| Target 5XX | EC2側が生成するHTTP 5XXエラー |
| UnHealthyHostCount | 異常なターゲット数 |
| EC2 CPU使用率 | CPU使用率70%以上 |
| RDSストレージ使用率 | ストレージ使用率80%以上 |

通知先にはSNSのメール購読を使用しています。

### CloudWatch Dashboard

以下の6種類のグラフを設定しました。

1. ALB Request Count
2. Target Health
3. ALB / Target 5XX Errors
4. EC2 CPU Utilization
5. RDS Free Storage Space
6. WAF Allowed / Blocked Requests

## 8. 動作検証結果

2026年11月21日にAWS環境を構築し、以下の項目について検証しました。

| 検証項目 | 結果 |
|---|---|
| Terraformによる54リソースの構築 | 成功 |
| EC2 User Dataによる自動構築 | 修正後成功 |
| Spring Bootの起動・自動起動設定 | 成功 |
| Spring BootからRDSへの接続 | 成功 |
| ALB Target Groupのヘルスチェック | Healthy |
| ALB経由のHTTP通信 | HTTP 200 |
| WAFの遮断対象リクエスト | HTTP 403 |
| WAFの許可対象リクエスト | HTTP 200 |
| WAF BLOCKログの記録 | 成功 |
| Spring Bootログの収集 | 成功 |
| RDSエラーログの収集 | 成功 |
| ALBアクセスログの収集 | 成功 |
| CloudWatch Alarm・SNS通知 | 異常検知・メール通知を確認 |
| CloudWatch Dashboard | 6種類のウィジェットを確認 |
| Terraformの最終差分確認 | No changes |
| Terraformによる全リソース削除 | 54リソース削除成功 |

CloudWatch Alarmは5種類すべての状態と設定を確認しましたが、閾値超過による実際の異常検知・通知まで検証したのはUnHealthyHostCountです。

詳細なコマンドと実行結果は、`docs/verification.md`にまとめます。

## 9. 障害調査・復旧

初回構築ではTerraformのApply自体は成功しましたが、ALB経由のアクセスでHTTP 502が発生しました。

調査の結果、EC2のUser Data実行時に、Amazon Linux 2023の`curl-minimal`と追加指定した`curl`が競合し、パッケージインストールに失敗していることが判明しました。

`cloud-init`の実行結果とログ、systemdのサービス状態、8080番ポートの待ち受けを確認して原因を特定しました。

User Dataから不要な`curl`のインストール指定を削除し、Terraformで再度Plan・Applyを実行しました。

EC2の`user_data_replace_on_change = true`によりEC2が置換され、関連するTarget Group Attachment、CloudWatch Alarm、Dashboardも更新されました。

修正時のTerraform実行結果：

```text
Plan: 2 to add, 2 to change, 2 to destroy.
```

再構築後にはSpring Boot、RDS接続、ALB経由のHTTP 200、Target GroupのHealthyを確認しました。

また、CloudWatch Alarmの履歴で、異常検知から復旧までの状態遷移も確認しています。

| 時刻（JST） | 状態 |
|---|---|
| 15:09 | INSUFFICIENT_DATA → OK |
| 15:19 | OK → ALARM |
| 15:55 | ALARM → OK |

詳細な原因調査、修正内容、復旧手順は`docs/troubleshooting.md`にまとめます。

## 10. Terraformの差分・削除検証

### 最終差分確認

構築・修正・動作検証の完了後、以下を実行しました。

```bash
terraform plan
```

結果：

```text
No changes. Your infrastructure matches the configuration.
```

Terraform Stateで管理対象の54リソースを確認しました。

### Destroy

検証終了後、アクセスログ用S3バケットに保存されたログオブジェクトを削除してからDestroyを実行しました。

```bash
terraform plan -destroy -out=destroy.tfplan
terraform show destroy.tfplan
terraform apply destroy.tfplan
```

Destroyの結果：

```text
Apply complete! Resources: 0 added, 0 changed, 54 destroyed.
```

その後、AWS上の残存リソースについても確認しました。

Terraform State保存用のS3 Backendバケットは削除していません。

**注意：** ALBアクセスログ用S3バケットは空でなければ削除できません。また、本構成ではRDSの最終スナップショットを作成しないため、Destroyするとデータは失われます。

## 11. CloudFormation版との比較

| 項目 | CloudFormation | Terraform |
|---|---|---|
| IaCツール | AWS CloudFormation | HashiCorp Terraform |
| 構成単位 | Stack / Nested Stack | Root Module / Child Module |
| 設定ファイル | YAML | HCL |
| 値の受け渡し | Parameters / Outputs | Variables / Outputs |
| リソース間参照 | Ref / GetAtt / ImportValue | Resource / Module参照 |
| 変更内容の確認 | Change Set | terraform plan |
| 構成状態の管理 | CloudFormation Stack | Terraform State |
| 作成・更新 | Stack操作 | terraform apply |
| 削除 | Stack削除 | terraform destroy / Destroy Plan |

CloudFormationとTerraformの両方で同じAWS環境を構築したことで、それぞれの構成管理、依存関係、変更内容の確認方法の違いを学習しました。

## 12. 改善案・今後の課題

今回の学習環境では、CloudFormationからの再構築と基本的な動作検証を優先しました。

実運用や複数環境への展開を想定する場合は、以下を改善課題とします。

| 改善項目 | 方向性 |
|---|---|
| HTTPS対応 | ACM証明書、ALB HTTPS Listenerの導入 |
| 可用性向上 | EC2 Auto Scaling、RDS Multi-AZの検討 |
| EC2の配置 | Private Subnet化と管理経路の見直し |
| IAMの最小権限化 | DB専用ユーザーとIAM権限の見直し |
| User Dataの改善 | アプリ取得バージョンの固定、初期化処理の堅牢化 |
| Terraformの再利用性 | サブネットCIDRやリソース名の変数化 |
| CIの導入 | GitHub Actionsでfmt・validateなどを自動検証 |
| セキュリティチェック | Terraform向けの静的解析・ポリシー検証 |
| テストの拡張 | アラーム閾値超過、異常系の自動テスト |

これらは今後の改善候補であり、今回の学習環境で実装済みの内容ではありません。

## 13. 注意事項

本リポジトリは学習を目的としたものです。

AWSリソースの作成・稼働には料金が発生します。EC2やRDSを停止しても、ALB、WAF、ストレージなどの料金が発生する場合があるため、検証後は不要なリソースを削除してください。

`terraform.tfvars`、Terraform State、Planファイル、秘密鍵、認証情報などの機密情報はGitHubに保存しないでください。

また、TerraformのDestroyではリソースやデータが削除されるため、実行前に削除対象を必ず確認してください。

この環境は2026年11月21日に構築・動作検証・削除を実施しています。
