# AWS CloudFormation Nested Stacks

## 1. 概要

RaiseTechのAWS学習課題で作成したCloudFormationテンプレートを、Nested Stacks構成へ再編成した学習用プロジェクトです。

個別にデプロイしていた7つのCloudFormationスタックを、親スタック（root.yaml）から一括で作成・管理できるようにしました。

今回の構成では、親スタックから各子スタックへParametersを渡し、子スタックのOutputsを参照してリソース間の依存関係を管理しています。

### 目的

- Nested StacksによるCloudFormationの構成管理を学ぶ
- 個別スタックとNested Stacksの違いを理解する
- Parameters / Outputsを使った子スタック間の値の受け渡しを実践する
- DependsOnによるリソース作成順序の制御を理解する
- AWS CLIによる一括デプロイと動作検証を行う

## 2. システム構成

AWS東京リージョン（ap-northeast-1）に、Spring Bootアプリケーションを実行するWeb環境を構築します。

### 構成概要

- VPC内に2つのPublic Subnetと2つのPrivate Subnetを配置
- Public SubnetにALBとEC2を配置
- Private SubnetにRDS for MySQLを配置
- ALBからEC2のSpring BootアプリケーションへHTTP:8080で通信
- EC2からRDSへMySQL:3306で接続
- AWS WAFでALBへのリクエストを検査
- ALBアクセスログをS3へ保存
- アプリケーションログ、WAFログ、RDSエラーログをCloudWatch Logsへ送信
- CloudWatch AlarmとSNSで監視・メール通知
- CloudWatch Dashboardで主要なメトリクスを可視化

### ネットワーク構成

| 項目 | 設定 |
|---|---|
| リージョン | ap-northeast-1 |
| VPC CIDR | 10.0.0.0/16 |
| Public Subnet A | 10.0.1.0/24 |
| Public Subnet C | 10.0.2.0/24 |
| Private Subnet A | 10.0.11.0/24 |
| Private Subnet C | 10.0.12.0/24 |
| EC2 | Amazon Linux 2023 / t3.micro |
| RDS | MySQL / db.t3.micro |
| ALB | Internet-facing |

この構成は学習用であり、本番環境向けの可用性・セキュリティ要件をすべて満たすものではありません。

## 3. ディレクトリ構成

```text
cloudformation/
├── templates/               # 個別スタック版
│   ├── network.yaml
│   ├── security.yaml
│   ├── database.yaml
│   ├── logging.yaml
│   ├── application.yaml
│   ├── waf.yaml
│   └── monitoring.yaml
│
└── nested/                  # Nested Stacks版
    ├── README.md
    ├── root.yaml            # 親スタック
    └── stacks/
        ├── network.yaml
        ├── security.yaml
        ├── database.yaml
        ├── logging.yaml
        ├── application.yaml
        ├── waf.yaml
        └── monitoring.yaml
```

`templates/` は個別スタック版として保持し、`nested/` では親スタックから7つの子スタックを管理します。

## 4. 各スタックの役割

| スタック | 主なリソース | 役割 |
|---|---|---|
| NetworkStack | VPC、Subnet、IGW、Route Table | ネットワーク基盤 |
| SecurityStack | Security Group | 通信制御 |
| LoggingStack | S3、CloudWatch Logs | ログ保存基盤 |
| DatabaseStack | RDS、DB Subnet Group | データベース |
| ApplicationStack | EC2、IAM Role、ALB、Target Group | アプリケーション実行環境 |
| WafStack | WAF WebACL、Association、LoggingConfiguration | Webアクセス制御 |
| MonitoringStack | CloudWatch Alarm、Dashboard、SNS | 監視・通知 |

## 5. Nested Stacksの依存関係

親スタックでは、子スタックのOutputsを取得し、別の子スタックのParametersへ渡します。

### 主な依存関係

| 子スタック | 依存する子スタック |
|---|---|
| NetworkStack | なし |
| SecurityStack | NetworkStack |
| LoggingStack | なし |
| DatabaseStack | NetworkStack、SecurityStack、LoggingStack |
| ApplicationStack | NetworkStack、SecurityStack、DatabaseStack、LoggingStack |
| WafStack | ApplicationStack、LoggingStack |
| MonitoringStack | ApplicationStack、DatabaseStack |

CloudFormationはOutputsへの参照による暗黙的な依存関係を認識し、作成順序を制御します。

### Parameters / Outputsの受け渡し

例：NetworkStackで作成したVPC IDをSecurityStackへ渡す場合

```yaml
SecurityStack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: stacks/security.yaml
    Parameters:
      MyIP: !Ref MyIP
      VpcId: !GetAtt NetworkStack.Outputs.VpcId
```

`NetworkStack.Outputs.VpcId` を参照することで、NetworkStackの作成結果をSecurityStackで利用できます。

### RDSロググループの作成順序

RDSのエラーログをCloudWatch Logsへ配信するため、LoggingStackでRDS用ロググループを先に作成します。

```yaml
DatabaseStack:
  Type: AWS::CloudFormation::Stack
  DependsOn: LoggingStack
```

親スタックからLoggingStackとDatabaseStackへ同じ `RdsInstanceIdentifier` を渡すことで、ロググループ名とRDSインスタンス識別子を一致させています。

DatabaseStackでは、RDS作成時から以下を有効にします。

```yaml
EnableCloudwatchLogsExports:
  - error
```

これにより、RDS作成後にログ配信設定を手動更新する必要がない構成としています。

## 6. デプロイ手順

### 前提条件

- AWS CLIがインストールされている
- AWS認証情報が設定されている
- CloudFormationなど必要なAWSサービスへの権限がある
- 東京リージョンにEC2キーペアが作成されている
- CloudFormationテンプレート保存用のS3バケットが作成されている
- cfn-lintがインストールされている

以下のコマンドは、リポジトリのルートディレクトリから実行します。

### 6.1 テンプレートの構文チェック

子スタックのチェック：

```bash
cfn-lint cloudformation/nested/stacks/*.yaml
```

親スタックのチェック：

```bash
cfn-lint -i W3002 -- cloudformation/nested/root.yaml
```

`W3002` は、TemplateURLにローカルファイルを指定しているために発生する警告です。

AWS CLIの `package` コマンドでS3 URLへ変換するため、この警告のみ除外します。

### 6.2 テンプレートのパッケージ化

```bash
aws cloudformation package \
  --template-file cloudformation/nested/root.yaml \
  --s3-bucket <テンプレート保存用バケット名> \
  --s3-prefix raisetech-nested \
  --output-template-file cloudformation/nested/packaged.yaml \
  --region ap-northeast-1
```

このコマンドにより、7つの子テンプレートがS3にアップロードされ、親テンプレート内のTemplateURLがS3 URLへ変換されます。

生成されたテンプレートをチェックします。

```bash
cfn-lint cloudformation/nested/packaged.yaml
```

`packaged.yaml` は生成ファイルのため、Git管理対象から除外します。

### 6.3 変更セットの作成

```bash
aws cloudformation deploy \
  --template-file cloudformation/nested/packaged.yaml \
  --stack-name raisetech-nested \
  --parameter-overrides \
    MyIP=<接続元IPアドレス/32> \
    NotificationEmail=<通知先メールアドレス> \
    Keypair=<EC2キーペア名> \
  --capabilities CAPABILITY_IAM \
  --no-execute-changeset \
  --region ap-northeast-1
```

`--no-execute-changeset` を指定することで、リソースの作成前に変更内容を確認できます。

### 6.4 変更セットの実行

AWS CloudFormationコンソールで以下を確認します。

1. `raisetech-nested` の変更セットを開く
2. 7つのNested Stacksが追加対象になっていることを確認
3. 変更セットを実行
4. 親スタックと子スタックの作成状況を確認

最終的に親スタックが `CREATE_COMPLETE` になれば、スタック作成は完了です。

### 6.5 Outputsの確認

```bash
aws cloudformation describe-stacks \
  --stack-name raisetech-nested \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table \
  --region ap-northeast-1
```

主なOutputs：

| Output | 内容 |
|---|---|
| AlbDnsName | ALBのDNS名 |
| RdsEndpoint | RDSのエンドポイント |
| WafArn | WAF WebACLのARN |
| AlarmTopicArn | SNSトピックのARN |

## 7. 動作検証結果

Nested Stacksで環境を構築した後、以下の動作を確認しました。

### 7.1 EC2・アプリケーション

| 検証項目 | 結果 |
|---|---|
| CloudFormation一括構築 | 成功 |
| cloud-init | done |
| raisetech-app.service | active |
| ALB経由のHTTP通信 | HTTP 200 |
| Spring Bootのデータ表示 | 成功 |

EC2のUser Dataにより、必要なパッケージの導入、アプリケーションの配置、systemdサービスの設定を実施しています。

RDSの認証情報はAWS Secrets Managerで管理し、EC2のIAM Roleに必要な参照権限を付与しています。

### 7.2 WAF

カスタムルール `BlockTestHeader` を使用して動作確認を行いました。

通常アクセス：

```bash
curl -i http://<ALB-DNS名>
```

結果：HTTP 200

遮断対象のヘッダーを付与：

```bash
curl -i \
  -H 'x-raisetech-test: block-me' \
  http://<ALB-DNS名>
```

結果：HTTP 403 Forbidden

CloudWatch LogsでもBLOCKログを確認しました。

### 7.3 ログ収集

| ログ | 保存先 | 結果 |
|---|---|---|
| ALBアクセスログ | S3 | 保存確認 |
| WAF BLOCKログ | CloudWatch Logs | 保存確認 |
| Spring Bootアプリケーションログ | CloudWatch Logs | 保存確認 |
| RDSエラーログ | CloudWatch Logs | 保存確認 |

主なログ設定：

- ALBアクセスログ用S3オブジェクト：14日で期限切れ
- アプリケーションログ：14日保持
- WAFログ：14日保持
- RDSエラーログ：14日保持

### 7.4 監視・通知

CloudWatchで以下の5つのアラームを作成しました。

| アラーム名 | 監視内容 |
|---|---|
| raisetech-alb-5xx | ALBの5XXエラー |
| raisetech-target-5xx | ターゲットの5XXエラー |
| raisetech-unhealthy-host | 異常なALBターゲット |
| raisetech-ec2-high-cpu | EC2 CPU使用率 |
| raisetech-rds-high-storage | RDSストレージ使用率 |

SNSトピックの作成とメール通知を確認しました。

### 7.5 CloudWatch Dashboard

`raisetech-infrastructure` ダッシュボードに、以下の6つのグラフが作成されていることを確認しました。

1. ALB Request Count
2. Target Health
3. ALB / Target 5XX Errors
4. EC2 CPU Utilization
5. RDS Free Storage Space
6. WAF Allowed / Blocked Requests

検証時点では、5XXエラーのグラフにはデータが表示されていませんでした。

5XXエラーのメトリクスは、エラーが発生していない場合、データが報告されず空のグラフになることがあります。

## 8. 個別スタック版との比較

| 比較項目 | 個別スタック版 | Nested Stacks版 |
|---|---|---|
| 管理単位 | 独立した7スタック | 親スタックと7つの子スタック |
| デプロイ | スタックごとに実行 | 親スタックから一括実行 |
| 値の受け渡し | Export / ImportValue | Parameters / Outputs / GetAtt |
| 依存関係 | スタック間参照や実行順序で管理 | 親スタックで依存関係を管理 |
| 更新 | 個別スタック単位 | 原則として親スタック経由 |
| 削除 | 個別に削除 | 親スタックから一括削除 |

### Nested Stacksを採用した理由

今回は、個別スタック版ですでに構築した7つのテンプレートを再利用し、以下を実現するためNested Stacksを採用しました。

- 環境構築を一括で実行する
- スタック間の依存関係をCloudFormationで管理する
- 手動でのデプロイ順序の指定を減らす
- 子スタックのテンプレートを機能別に分離する

実務では、更新頻度、運用責任、リソースのライフサイクルなどに応じて、独立したスタックとNested Stacksを使い分ける必要があります。

## 9. 削除手順

検証終了後は、AWSの利用料金を抑えるため、作成したリソースを削除します。

### 9.1 ALBアクセスログ用S3バケットの確認

LoggingStackで作成したALBアクセスログ用S3バケットにオブジェクトが残っている場合、CloudFormationによるバケット削除が失敗する可能性があります。

削除前に対象バケットを確認し、今回の検証で作成したログを削除します。

```bash
aws s3 rm s3://<ALBアクセスログ用バケット名>/ \
  --recursive \
  --region ap-northeast-1
```

この操作は取り消せません。対象バケットを十分確認してから実行してください。

ALBが稼働している間は新しいログが追加される可能性があるため、削除処理が失敗した場合はCloudFormationのイベントを確認します。

### 9.2 親スタックの削除

```bash
aws cloudformation delete-stack \
  --stack-name raisetech-nested \
  --region ap-northeast-1
```

削除完了を待機する場合：

```bash
aws cloudformation wait stack-delete-complete \
  --stack-name raisetech-nested \
  --region ap-northeast-1
```

親スタックを削除すると、管理対象の子スタックも削除対象になります。

RDSなどのデータも削除される設定のため、必要なデータが残っていないか事前に確認してください。

### 9.3 テンプレート保存用S3バケット

`aws cloudformation package` 用にCLIから作成したS3バケットは、親スタックの削除では自動削除されません。

不要になった場合は、保存されたテンプレートを確認したうえで別途削除します。

## 10. 注意事項

- 学習・検証用の構成であり、本番運用を想定したものではありません
- ALBのHTTP通信にはHTTPS終端を設定していません
- EC2はPublic Subnetに配置しています
- RDSはSingle-AZ構成です
- 一部のAWSリソース名は固定値を使用しているため、同じアカウント・リージョンで複数環境を構築すると名前が競合する可能性があります
- EC2のUser Dataでは外部GitHubリポジトリからアプリケーションを取得するため、デプロイ時に外部リポジトリやパッケージ配布元へアクセスできる必要があります
- IAM権限やS3バケットのアクセス制御は、利用環境に応じて確認する必要があります
- AWSリソースの作成中は利用料金が発生します
- シークレットや認証情報をGitHubへ登録しないように注意してください

## 11. 学習を通じて理解したこと

今回の学習では、個別スタック版からNested Stacks版へ移行することで、以下を実践しました。

- CloudFormationテンプレートの機能別分割
- Export / ImportValueとParameters / Outputsの違い
- GetAttを使った子スタック間の値の受け渡し
- DependsOnによる作成順序の明示
- packageによるローカルテンプレートのS3アップロード
- 変更セットによるデプロイ前の確認
- CloudFormationによるAWS環境の一括構築
- アプリケーション、ログ、監視、WAFの動作検証

Nested Stacksによって、複数のAWSリソース群を1つの親スタックからまとめて構築できることを確認しました。

同時に、リソースの役割やライフサイクルによって適切な管理単位を選択することの重要性を学びました。
