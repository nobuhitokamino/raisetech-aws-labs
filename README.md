# RaiseTech AWS Labs

RaiseTechのAWS課題を通じて取り組んだ、インフラ構築・設定・動作検証の学習記録です。

AWSの各種サービスやInfrastructure as Code（IaC）の理解を深めることを目的としています。

## 1. 実装概要

AWS CloudFormationを使用し、Spring Bootアプリケーションを実行するAWSインフラ環境を構築しました。

機能ごとにスタックを分割し、アプリケーション環境に加えて、アクセス制御・ログ収集・監視・通知の仕組みを実装しています。

CloudFormationでは、機能ごとにスタックを個別管理する構成に加え、Nested Stacksによる一括管理構成も実装しました。両方の構成を通じて、スタック間の依存関係やParameters・Outputsを利用した値の受け渡しについて学習しました。

また、CloudFormation Guardによるセキュリティ検証とGitHub ActionsによるCIを導入し、一部テンプレートの静的解析と検証を自動化しています。

主な構成は以下のとおりです。

- **VPC**：Public / Private Subnetを2つのAZに配置
- **EC2**：Amazon Linux 2023、Java 21、Spring Boot
- **RDS**：MySQL（Single-AZ）
- **ALB**：インターネットからのHTTPアクセスをEC2の8080番ポートへ転送
- **Security Group**：各リソース間の通信制御
- **Secrets Manager**：RDSの認証情報を自動管理
- **systemd**：Spring Bootアプリケーションのサービス管理・自動起動
- **AWS WAF**：AWSマネージドルールとカスタムルールによるアクセス制御
- **S3**：ALBアクセスログの保存
- **CloudWatch Logs**：アプリケーション・WAF・RDSのログ収集
- **CloudWatch Alarm**：メトリクスを利用した異常検知
- **Amazon SNS**：アラーム発報時のメール通知
- **CloudWatch Dashboard**：主要メトリクスの一元表示

なお、ALBは複数AZを使用していますが、EC2とRDSはそれぞれ1台の構成です。

## 2. ディレクトリ構成

| ファイル | 内容 |
|---|---|
| `cloudformation/templates/network.yaml` | VPC、Subnet、IGW、Route Table |
| `cloudformation/templates/security.yaml` | ALB・EC2・RDSのSecurity Group |
| `cloudformation/templates/database.yaml` | RDS、DB Subnet Group、Secrets Manager連携、RDSログ配信 |
| `cloudformation/templates/application.yaml` | EC2、ALB、Target Group、Listener、IAM、User Data、CloudWatch Agent |
| `cloudformation/templates/logging.yaml` | ALBアクセスログ用S3バケット、CloudWatch Log Group |
| `cloudformation/templates/waf.yaml` | WebACL、ALBへの関連付け、WAFログ配信 |
| `cloudformation/templates/monitoring.yaml` | CloudWatch Alarm、SNS、CloudWatch Dashboard |
| `.github/workflows/cloudformation-check.yaml` |	GitHub Actionsによる自動検証 |
| `cloudformation/guard/rules/rds.guard` | RDSのセキュリティルール |
| `cloudformation/guard/tests/rds_tests.yaml` | Guardの単体テスト |
| `cloudformation/docs/guard-validation.md` |セキュリティ検証結果 |
| `cloudformation/nested/root.yaml` | Nested Stacksの親テンプレート |
| `cloudformation/nested/stacks/` |	7つの子スタック用テンプレート |
| `cloudformation/nested/README.md` |	Nested Stacksの構築手順・動作検証結果 |

## 3. CloudFormationスタックの構築手順

CloudFormationでは、個別スタック版とNested Stacks版の2種類の構成を実装しました。

個別スタック版では、Outputs / Export と Fn::ImportValue を使用してスタック間の値を連携しています。

Nested Stacks版では、親スタックから子スタックへParametersを渡し、子スタックのOutputsを参照することで、依存関係を管理しています。

### 個別スタック版の構築
#### スタックの作成順序

以下の順序でスタックを作成します。

1. `network`
2. `security`
3. `database`（RDSログエクスポートは無効）
4. `logging`
5. `database` の更新（RDSログエクスポートを有効化）
6. `application`
7. `waf`
8. `monitoring`

最終的なスタック数は7つです。RDSロググループとの競合を防ぐため、`database` スタックのみ初回作成後に更新します。

#### RDSログエクスポートの設定

RDSのエラーログはCloudWatch Logsへ送信しています。

初回構築時にRDSがロググループを自動作成すると、`logging` スタックで定義した同名のロググループと競合する可能性があります。

そのため、`database.yaml` では `EnableRdsLogExport` パラメータを使用し、ログ配信の有効・無効を切り替えられるようにしています。

| パラメータ値 | 動作 |
|---|---|
| `false` | RDSのエラーログエクスポートを有効にしない |
| `true` | RDSのエラーログをCloudWatch Logsへ送信する |

**初回構築手順**

1. `database` スタック作成時に `EnableRdsLogExport=false` を明示的に指定する。
2. `logging` スタックを作成し、RDS用ロググループを保持期間14日で作成する。
3. `database` スタックを更新し、`EnableRdsLogExport=true` に変更する。
4. CloudWatch LogsでRDSエラーログの配信を確認する。

パラメータのデフォルト値は `true` なので、初回構築時は必ず `false` を指定してください。

この手順により、RDSのログ配信設定とCloudWatch Logsの保持期間をCloudFormationで管理できます。

#### スタック名・Export名の運用ルール

各スタックのExport名は、`スタック名-出力名` の形式で定義しています。

例：

- `network-VpcId`
- `network-PublicSubnetAId`
- `network-PrivateSubnetAId`
- `database-RdsEndpoint`
- `database-RdsSecretArn`
- `database-RdsInstanceIdentifier`
- `logging-AlbLogsBucketName`
- `logging-WafLogGroupArn`
- `application-AlbArn`
- `application-AlbFullName`
- `application-TargetGroupFullName`
- `application-Ec2InstanceId`

各テンプレートでは、これらのExport名を `Fn::ImportValue` で参照しています。

そのため、スタック作成時は上記の名称を使用してください。

また、スタック間でExport値を参照するため、同じAWSアカウント・リージョン内で構築する必要があります。

#### 構築時の注意事項

- Securityスタックの `MyIP` パラメータには、SSH接続元のグローバルIPv4アドレスをCIDR形式（`/32`）で指定してください。
- EC2接続用のキーペアを事前に準備してください。
- Amazon Linux 2023のAMIは、SSMパブリックパラメータを利用して取得します。
- RDSのマスターパスワードはSecrets Managerで自動管理し、EC2のIAMロールを使用して取得します。
- SNSのメール通知を利用するには、届いた確認メールからサブスクリプションを承認する必要があります。
- パスワードや秘密鍵などの機密情報はGitHubに保存しないでください。

#### Securityスタックのデプロイ例（AWS CLI）

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

---
### Nested Stacks版による一括構築

個別に管理していた7つのCloudFormationスタックを、Nested Stacks構成へ再編成しました。

親スタック（`root.yaml`）から7つの子スタックを一括で作成・管理できる構成としています。

**個別スタック版との主な違い**

| 比較項目 | 個別スタック版 | Nested Stacks版 |
|---|---|---|
| 構成 | 独立した7スタック | 親スタックと7つの子スタック |
| デプロイ | スタックごとに実行 | 親スタックから一括実行 |
| 値の受け渡し | Export / ImportValue | Parameters / Outputs / GetAtt |
| 依存関係 | スタック間参照や作成順序で管理 | 親スタックで依存関係を管理 |

Nested Stacks版では、親スタックから子スタックへParametersを渡し、子スタックのOutputsを参照することで、必要な値の受け渡しと依存関係の管理を行っています。

また、`aws cloudformation package`によるテンプレートのS3アップロードと、変更セットによるデプロイ前の確認を実践しました。

**動作検証結果**

- 親スタックから7つの子スタックの一括作成に成功
- Spring Bootアプリケーションの起動とALB経由でのHTTP 200を確認
- WAFによるHTTP 403の遮断を確認
- ALB・アプリケーション・WAF・RDSのログ収集を確認
- CloudWatch Alarm・SNSによる通知とDashboardの表示を確認

Nested Stacks版の構成、デプロイ手順、依存関係、検証結果については、以下にまとめています。

**[Nested Stacks版の詳細README](cloudformation/nested/README.md)**

## 4. ログ収集・監視構成

### ログ収集

以下の4種類のログを収集しています。

| ログの種類 | 保存先 | 保存期間 |
|---|---|---|
| ALBアクセスログ | S3 | 14日 |
| Spring Bootアプリケーションログ | CloudWatch Logs | 14日 |
| WAFログ | CloudWatch Logs | 14日 |
| RDSエラーログ | CloudWatch Logs | 14日 |

Spring Bootのログは、EC2のUser DataでCloudWatch Agentをインストール・設定し、systemdのjournalから収集しています。

ALBアクセスログはS3へ保存し、WAFログとRDSエラーログはそれぞれのログ配信機能を利用してCloudWatch Logsへ送信しています。

### AWS WAF

以下の2種類のルールを設定しています。

| ルール | 内容 |
|---|---|
| `AWSManagedRulesCommonRuleSet` | AWSマネージドルールによる一般的なWeb攻撃への対策 |
| `BlockTestHeader` | 指定したHTTPヘッダーに一致するリクエストを遮断 |

カスタムルールでは、`x-raisetech-test: block-me` を指定したリクエストを遮断するよう設定しています。

### CloudWatch Alarm・SNS

CloudWatch Alarmで以下の5項目を監視しています。

| アラーム | 監視内容 |
|---|---|
| ALB 5XX | ALB自身が返すHTTP 5XXエラー |
| Target 5XX | アプリケーション側が返すHTTP 5XXエラー |
| UnHealthyHostCount | 異常なターゲット数 |
| EC2 CPU使用率 | EC2のCPU負荷 |
| RDSストレージ使用率 | 空きストレージ容量から算出した使用率 |

アラームがALARM状態になると、SNSトピックを経由してメール通知する構成です。

### CloudWatch Dashboard

以下の6つのメトリクスグラフを1つのダッシュボードに表示しています。

1. ALBリクエスト数
2. ターゲットの正常性（Healthy / Unhealthy）
3. ALB・TargetのHTTP 5XXエラー
4. EC2 CPU使用率
5. RDS空きストレージ容量
6. WAFの許可・遮断リクエスト数

## 5. 動作確認

以下の項目について動作確認を実施しました。

### アプリケーション・インフラ

- CloudFormationによる個別7スタックの構築
- Nested Stacksによる親スタックと7つの子スタックの一括構築
- User Dataによるアプリケーションの自動セットアップ
- systemdによるSpring Bootの起動と自動起動設定
- EC2再起動後のアプリケーション起動
- Spring BootからRDSへの接続・データ取得
- ALB経由でのHTTP 200レスポンス
- Secrets Managerへの移行後の再構築・動作確認
- EC2の置換後の動作確認

### ログ収集

- ALBアクセスログのS3への保存
- Spring BootログのCloudWatch Logsへの送信
- WAFログのCloudWatch Logsへの送信
- RDSエラーログのCloudWatch Logsへの送信

### WAF・監視・通知

- 通常アクセスでHTTP 200を確認
- カスタムルールに一致するリクエストでHTTP 403を確認
- WAFログに `BlockTestHeader` による `BLOCK` が記録されることを確認
- CloudWatch AlarmからSNSへのメール通知を確認
- Spring Bootを停止してALBターゲットの異常を検知
- `UnHealthyHostCount` アラームの発報とSNS通知を確認
- Spring Boot復旧後のアラーム解除を確認
- CloudWatch Dashboardで6つのグラフの表示を確認

なお、EC2 CPU使用率とRDSストレージ使用率については、実際に閾値を超えた状態でのアラーム検証は行っていません。

### CloudFormationの静的検証・CI

CloudFormationテンプレートの品質とセキュリティを確認するため、`cfn-lint`と`CloudFormation Guard`を導入しました。

また、GitHub Actionsを使用して、mainブランチへのpushおよびPull Requestを契機に、検証を自動実行するCIを構築しました。

**検証内容**

| ツール | 検証内容 | 結果 |
|---|---|---|
| cfn-lint | 個別スタック版7ファイルとNested Stacks版8ファイルの静的解析 | 成功 |
| cfn-guard test | RDSの非公開ルールに対する4件の単体テスト | 全件成功 |
| cfn-guard validate | database.yamlのRDSパブリックアクセス設定を検証 | PASS |
| GitHub Actions | 上記の検証をUbuntu Runner上で自動実行 | 成功 |

`cfn-lint`による静的解析は、個別スタック版7テンプレートとNested Stacks版の親・子8テンプレート、合計15テンプレートを対象としています。

Nested Stacks版の親テンプレートについては、デプロイ前に`aws cloudformation package`でローカルのTemplateURLをS3 URLへ変換する構成のため、`W3002`警告のみを除外して検証しています。

GitHub Actionsにより、個別スタック版とNested Stacks版の計15テンプレートの静的解析、およびCloudFormation Guardによるセキュリティ検証が正常終了することを確認しました。

今回のGuardルールは、RDSの`PubliclyAccessible`が明示的に`false`であることを確認するものです。

なお、検証対象は上記のテンプレートとルールに限定しています。

**CIの異常系テスト**

GitHub Actionsがセキュリティルール違反を正しく検出できるか確認するため、テスト用ブランチで異常系テストを実施しました。

RDSの`PubliclyAccessible`を`false`から`true`へ一時的に変更し、Pull Requestを作成してCIを実行しました。

| 検証内容 | 結果 |
|---|---|
| 正常な設定でのCI実行 | 成功 |
| RDSのPubliclyAccessibleをtrueに変更 | GuardがFAILを検出 |
| GitHub Actionsによるルール違反の検出 | CI失敗 |
| 設定をfalseに戻して再実行 | CI成功 |

Guardの検証ログでは、`MyRDS`の`PubliclyAccessible`がルールに違反していることを確認しました。

これにより、正常な設定ではCIが成功し、セキュリティルール違反がある場合はCIが失敗すること、また修正後に再び成功することを確認できました。

検証はテスト用ブランチで行い、Pull Requestはmainブランチへマージせずにクローズしました。

**[異常系テストのPull Request（#6）](https://github.com/nobuhitokamino/raisetech-aws-labs/pull/6)**

**関連資料**

- [CloudFormation Guardの検証記録](cloudformation/docs/guard-validation.md)
- [GitHub Actionsワークフロー](.github/workflows/cloudformation-check.yaml)

## 6. 今後の学習予定

- CloudFormation Guardのセキュリティルール追加
- CIによる検証対象テンプレートの拡大
- 監視項目やアラーム閾値の見直し
- 構築・運用手順の改善

## 7. 注意事項

本リポジトリは学習を目的としたものです。

AWSリソースの作成・稼働には料金が発生する場合があります。EC2やRDSを停止しても、ストレージ、ALB、WAF、CloudWatchなどの料金が継続する場合があります。

また、RDSは停止可能な期間に制限があり、一定期間後に自動起動されます。

検証後は不要なリソースを削除し、課金状況を確認してください。

CloudFormationスタックの削除時には、`Fn::ImportValue` による依存関係に注意してください。

S3バケットは `DeletionPolicy` の設定によってスタック削除後も残る場合があります。また、RDSなどのリソースは削除時の設定によってデータが失われるため、必要なデータは事前にバックアップしてください。
