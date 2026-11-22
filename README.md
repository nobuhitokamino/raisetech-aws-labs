# RaiseTech AWS Labs

RaiseTechのAWS課題を通じて取り組んだ、AWSインフラの構築・設定・動作検証・障害対応の学習記録です。

AWS CloudFormationとTerraformを使用し、Spring Bootアプリケーションを実行するAWSインフラ環境を構築しました。

CloudFormationでは個別スタックとNested Stacksの両方を実装し、Terraformでは同じ用途のインフラ環境を7つのModuleに分割して再構築しています。

Infrastructure as Code（IaC）による構成管理だけでなく、AWS上での動作検証、ログ収集、監視・通知、障害調査、リソース削除までを実践しています。

## 1. 実装概要

### 共通のAWSインフラ構成

主に以下のAWSサービスと機能を使用しています。

| サービス・機能 | 実装内容 |
|---|---|
| VPC | 2つのAZにPublic / Private Subnetを配置 |
| EC2 | Amazon Linux 2023、Java 21、Spring Boot |
| RDS | MySQL（Single-AZ）、Secrets Managerによる認証情報管理 |
| ALB | HTTP:80からEC2の8080番ポートへ転送 |
| Security Group | ALB・EC2・RDS間の通信制御 |
| IAM | EC2からSecrets Managerなどを利用するための権限設定 |
| systemd | Spring Bootのサービス管理・自動起動 |
| AWS WAF | AWSマネージドルールとカスタムルールによるアクセス制御 |
| S3 | ALBアクセスログの保存 |
| CloudWatch Logs | アプリケーション・WAF・RDSのログ収集 |
| CloudWatch Alarm | 5種類の監視アラーム |
| Amazon SNS | 異常検知時のメール通知 |
| CloudWatch Dashboard | 主要メトリクスを6つのウィジェットで表示 |

ALBは2つのAZを使用していますが、EC2とRDSはそれぞれ1台です。EC2のAuto ScalingやRDSのMulti-AZは実装していません。

学習環境としてコストを抑え、基本的なAWSインフラ構築、アクセス制御、ログ収集、監視・通知の仕組みを検証しています。

### CloudFormation版

CloudFormationでは、以下の2種類の構成を実装しました。

- **個別スタック版**：機能ごとに分割した7スタックを個別管理
- **Nested Stacks版**：親スタックから7つの子スタックを一括管理

個別スタック版ではOutputs・Export・ImportValueを、Nested Stacks版ではParameters・Outputsを利用してスタック間の値を連携しています。

また、`cfn-lint`、CloudFormation Guard、GitHub Actionsを使用し、テンプレートの静的解析とセキュリティルールの検証を自動化しました。

正常な設定でCIが成功することに加え、テスト用にセキュリティルール違反を発生させた場合にCIが失敗し、修正後に成功することも確認しています。

**関連資料**

- [Nested Stacks版の詳細](cloudformation/nested/README.md)
- [CloudFormation Guard検証記録](cloudformation/docs/guard-validation.md)
- [GitHub Actionsワークフロー](.github/workflows/cloudformation-check.yaml)

### Terraform版

CloudFormationで構築したAWS環境をTerraformで再構築しました。

Root Moduleと7つのChild Moduleに分割し、Variables・Outputsによる値の受け渡し、リソース間の依存関係、S3 BackendによるState管理を実装しています。

**主な実装・検証結果**

| 項目 | 内容・結果 |
|---|---|
| Terraform管理リソース | 54リソース |
| Module構成 | 7モジュール |
| State管理 | S3 Backend、`use_lockfile`によるロック |
| 初回構築 | 54リソース作成成功 |
| アプリケーション | Spring Boot・RDS接続・ALB経由のHTTP 200 |
| AWS WAF | 通常アクセスHTTP 200、遮断対象HTTP 403 |
| ログ収集 | ALB・アプリケーション・WAF・RDSの4種類 |
| 監視・通知 | CloudWatch Alarmによる異常検知、SNSメール通知 |
| Dashboard | 6ウィジェットの作成・表示確認 |
| 障害対応 | User Dataのエラー調査・修正・EC2置換・復旧 |
| 最終差分確認 | `No changes` |
| 環境削除 | 54リソース削除成功、残存リソース確認済み |

初回構築では、Amazon Linux 2023の`curl-minimal`と、User Dataで追加インストールした`curl`が競合し、Spring Bootが起動しない問題が発生しました。

`cloud-init`のログから原因を特定し、User Dataを修正してTerraformでEC2を置換しました。修正後はALB経由のHTTP 200を確認し、CloudWatch AlarmもOK状態へ復旧しました。

これにより、Terraformによる構築だけでなく、障害調査・コード修正・再構築・復旧・削除の一連の流れを実践しました。

**関連資料**

- [Terraform版の詳細README](terraform/README.md)
- [Terraform動作検証記録](terraform/docs/verification.md)
- [Terraform障害調査・復旧記録](terraform/docs/troubleshooting.md)

なお、Terraform版のGitHub ActionsによるCIは、今後の実装課題です。

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
| `terraform/README.md` | Terraform版の構成・設計・構築手順・実装結果 |
| `terraform/environments/dev/` | Root Module、Backend、Provider、変数、Outputs |
| `terraform/modules/` | 7つのChild Module |
| `terraform/templates/user_data.sh.tftpl` | EC2のUser Dataテンプレート |
| `terraform/docs/verification.md` | Terraform動作検証記録 |
| `terraform/docs/troubleshooting.md` | Terraform障害調査・復旧記録 |
| `terraform/docs/images/` | 動作検証のスクリーンショット |

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

## 4. CloudFormation版のログ収集・監視構成

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

## 5. CloudFormation版の動作確認

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

`cfn-lint`とAWS CloudFormation Guardを使用し、CloudFormationテンプレートの静的解析とセキュリティ検証を実施しています。

GitHub Actionsでは、pushおよびPull Request時に検証を自動実行します。

**検証内容**

| ツール | 検証内容 | 結果 |
|---|---|---|
| cfn-lint | 個別版7件・Nested版8件、計15テンプレート | 成功 |
| Guard test | RDS非公開ルール4件 | 全件成功 |
| Guard test | RDS暗号化ルール4件 | 全件成功 |
| Guard test | SSH公開制限ルール26件 | 全件成功 |
| Guard validate | RDS非公開（個別版・Nested版） | 2件PASS |
| Guard validate | RDSストレージ暗号化（個別版・Nested版） | 2件PASS |
| Guard validate | SSH公開制限（個別版・Nested版） | 2件PASS |
| GitHub Actions | 上記の検証を自動実行 | 成功 |

`cfn-lint`による静的解析は、個別スタック版7テンプレートとNested Stacks版の親・子8テンプレート、合計15テンプレートを対象としています。

Nested Stacks版の親テンプレートについては、デプロイ前に`aws cloudformation package`でローカルのTemplateURLをS3 URLへ変換する構成のため、`W3002`警告のみを除外して検証しています。

CloudFormation Guardでは、以下の3種類のセキュリティルールを定義しています。

- `RDS_NOT_PUBLIC`：RDSのパブリックアクセス禁止
- `RDS_STORAGE_ENCRYPTED`：RDSのストレージ暗号化を必須とする
- `NO_PUBLIC_SSH`：Security GroupのSSH公開制限

SSH公開制限では、IPv4・IPv6、全プロトコル許可、Security Group内部と独立Ingressの両方を検証対象としています。

また、`!Ref MyIP`を使用する場合は、参照先パラメータの`AllowedPattern`も検証しています。

GitHub Actionsにより、15テンプレートの静的解析、Guardの単体テスト34件、3種類のセキュリティルールを個別スタック版とNested Stacks版の両方に適用した計6件の検証が正常終了することを確認しました。

詳細な検証内容と結果は、[CloudFormation Guard検証記録](cloudformation/docs/guard-validation.md)を参照してください。

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

## 6. CloudFormation版のレビュー結果・改善案・今後の課題

### レビュー結果

CloudFormationによるインフラ構築とAWS上での動作検証を完了した後、個別スタック版・Nested Stacks版のテンプレートについて、構成の整合性、セキュリティ、ログ収集・監視、運用面のレビューを実施しました。

主な確認項目は以下のとおりです。

- VPC、Subnet、Route Table、Security Groupの通信設定
- スタック間の依存関係とParameters・Outputsの参照
- IAMロール、Secrets Manager、RDS認証情報の管理
- EC2 User Dataによるアプリケーション起動とDB初期化
- ALB・WAF・CloudWatch Logsのログ出力設定
- CloudWatch Alarm、SNS、Dashboardの監視設定
- cfn-lint、CloudFormation Guard、GitHub Actionsによる自動検証

レビュー中に、Nested Stacks版のSSH接続元パラメータの入力制限と、VPC CIDRの受け渡し方法を改善しました。また、Nested Stacks版もGuardの検証対象に追加し、GitHub Actionsで正常終了することを確認しました。

今回確認した範囲では、直ちに修正が必要と判断できる重大な問題は見つかりませんでした。ただし、静的解析やコードレビューだけで、すべての運用条件における安全性や動作を保証するものではありません。

### 改善案

現在の構成は動作確認済みのため、大きな変更は行わず、保守性やセキュリティをさらに高めるための改善候補として整理しています。

| 改善項目 | 優先度 | 改善の方向性 |
|---|---|---|
| DBユーザーの権限分離 | 中 | アプリケーション専用DBユーザーを用意し、最小権限にする |
| MySQLの認証情報の受け渡し | 中 | `MYSQL_PWD`に代わる方法を検討する |
| WAFの機密情報保護 | 中 | サンプリングリクエストの取り扱いとデータ保護設定を見直す |
| S3バケットの削除手順 | 低 | アクセスログが残っている場合の削除方法を明確にする |
| ネットワーク設定の管理 | 低 | サブネットCIDRのパラメータ化などを検討する |
| Security Groupの設定 | 低 | 説明文の改善と必要に応じたアウトバウンド制限を検討する |
| 固定リソース名 | 低 | 複数環境を同時構築する場合の名前競合対策を検討する |

これらは現在の学習環境で直ちにすべて変更する必要があるものではなく、実運用や複数環境への展開を想定した場合の改善候補です。

なお、個別スタック版のRDSロググループ作成時の競合については、RDSログエクスポートを無効にしてDatabaseStackを作成し、LoggingStack作成後に有効化する手順を実装・文書化済みです。

### 今後の課題

今回の学習では基本的なAWSインフラの構築、セキュリティ設定、ログ収集、監視、自動検証までを実装しました。

今後は、以下の項目を発展的な学習課題とします。

- **可用性の向上**：EC2のAuto ScalingやRDSのMulti-AZ構成を学習し、障害時の影響を軽減できる設計を検討する。
- **セキュリティ検証の拡張**：CloudFormation Guardのルールを追加し、より多くのセキュリティ要件を自動検証する。
- **CI/CDの発展**：現在の静的解析・セキュリティ検証に加え、デプロイ前確認やデプロイ自動化を検討する。
- **監視・障害対応の改善**：アラーム閾値の見直しや、障害発生時の調査・復旧手順の整備を進める。

これらは今回の構築で未実装の項目を整理したものであり、現在の学習環境の完成条件ではありません。

## 7. 注意事項

本リポジトリは学習を目的としたものです。

AWSリソースの作成・稼働には料金が発生する場合があります。EC2やRDSを停止しても、ストレージ、ALB、WAF、CloudWatchなどの料金が継続する場合があります。

また、RDSは停止可能な期間に制限があり、一定期間後に自動起動されます。

検証後は不要なリソースを削除し、課金状況を確認してください。

CloudFormationスタックの削除時には、`Fn::ImportValue` による依存関係に注意してください。

S3バケットは `DeletionPolicy` の設定によってスタック削除後も残る場合があります。また、RDSなどのリソースは削除時の設定によってデータが失われるため、必要なデータは事前にバックアップしてください。
