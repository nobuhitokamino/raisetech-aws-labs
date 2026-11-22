# Terraform 障害調査・復旧記録

## 1. 概要

Terraformを使用してRaiseTechのAWS課題環境を構築した際、EC2のUser Data実行に失敗し、ALB経由でSpring BootアプリケーションへアクセスするとHTTP 502 Bad Gatewayが返される障害が発生しました。

調査の結果、Amazon Linux 2023にインストールされている`curl-minimal`と、User Dataで追加指定した`curl`パッケージの競合が原因であることが判明しました。

User Dataのパッケージインストール処理でエラーが発生したため、後続のSpring Bootセットアップと起動処理が実行されていませんでした。

原因となったTerraformのUser Dataテンプレートを修正し、EC2を置換することで復旧しました。

また、障害発生時にはCloudWatch Alarmがターゲットの異常を検知し、SNSによるメール通知が行われました。

### 障害概要

| 項目 | 内容 |
|---|---|
| 発生日 | 2026年11月21日 |
| 対象環境 | Terraformで構築したAWS学習環境 |
| リージョン | ap-northeast-1（東京） |
| 発生事象 | ALB経由のHTTPアクセスで502 Bad Gateway |
| 影響対象 | Spring BootアプリケーションへのHTTPアクセス |
| 原因 | `curl-minimal`と`curl`のパッケージ競合 |
| 対応 | User Dataの修正とTerraformによるEC2置換 |
| 復旧結果 | HTTP 200、Target Group Healthy |
| 最終確認 | Terraform PlanでNo changes |

## 2. システム構成と影響範囲

障害発生時の通信経路は以下のとおりです。

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

Terraformによる54リソースの作成自体は正常終了していました。

しかし、EC2は起動していてもSpring Bootが正常に起動していない状態でした。

そのため、ALBからアプリケーションへのHTTP通信が正常に処理されませんでした。

本構成ではEC2が1台のみであり、アプリケーションを実行する別のEC2は配置していません。

なお、後続の検証でRDSの稼働と接続を確認できていますが、初回障害発生時点でRDS自体に異常があったことを示す証拠はありませんでした。

## 3. 障害の検知

### 3.1 ALBへのHTTPアクセス

Terraform Applyの完了後、ALBのDNS名を取得し、HTTPアクセスを実施しました。

**実行コマンド**

```bash
ALB_DNS=$(terraform output -raw alb_dns_name)

curl -i --max-time 10 "http://$ALB_DNS/"
```

**実行結果**

```text
HTTP/1.1 502 Bad Gateway
Server: awselb/2.0
```

期待していたHTTP 200ではなく、ALBからHTTP 502が返されました。

この時点では、ALBとEC2間の通信設定、アプリケーションの起動状態、リクエスト処理など、複数の原因が考えられました。

### 3.2 CloudWatch Alarm・SNS

ALBのターゲットが異常状態となり、CloudWatchの`UnHealthyHostCount`アラームがALARM状態へ遷移しました。

SNSによるメール通知も受信しました。

これにより、監視・通知の仕組みが実際の異常を検知できていることを確認しました。

## 4. 原因調査

今回は、ALBからアプリケーションへ正常にアクセスできない原因を、EC2の状態とOS内部のログから切り分けました。

### 4.1 EC2の稼働状態

AWS CLIでEC2の状態を確認しました。

**実行コマンド**

```bash
aws ec2 describe-instances \
  --instance-ids "$(terraform output -raw ec2_instance_id)" \
  --region ap-northeast-1 \
  --query 'Reservations[].Instances[].[State.Name,PublicIpAddress,PrivateIpAddress]' \
  --output table
```

**確認結果**

```text
State.Name: running
```

EC2インスタンスは起動していました。

ただし、EC2の`running`は仮想マシンの稼働状態を示すものであり、User Dataの実行成功やSpring Bootの正常起動を保証するものではありません。

そのため、EC2にSSH接続し、OS内部の調査へ進みました。

### 4.2 cloud-initの状態確認

**実行コマンド**

```bash
sudo cloud-init status --long
```

**実行結果**

```text
status: error

detail:
('scripts-user', RuntimeError(
  'Runparts: 1 failures (part-001) in 1 attempted commands'
))
```

`status: error`が表示され、User Dataに相当する`scripts-user`の実行に失敗していることを確認しました。

ここから、Spring Bootの問題を調査する前に、User Dataの処理が正常に完了しているか確認する必要があると判断しました。

### 4.3 cloud-initログの調査

**実行コマンド**

```bash
sudo tail -n 100 /var/log/cloud-init-output.log
```

**確認できたエラー（抜粋）**

```text
package curl-minimal-... from @System
conflicts with curl provided by curl-...

(try to add '--allowerasing' to command line
to replace conflicting packages
or '--skip-broken' to skip uninstallable packages)
```

Amazon Linux 2023にインストールされている`curl-minimal`と、User Dataの`dnf install`で指定した`curl`が競合していました。

User Dataでは次のように、エラー発生時に処理を終了する設定にしていました。

```bash
#!/bin/bash
set -euo pipefail
```

この設定により、パッケージインストールの失敗後、後続処理は実行されませんでした。

### 4.4 systemdサービスの確認

**実行コマンド**

```bash
sudo systemctl status raisetech-app --no-pager -l
```

**実行結果**

```text
Unit raisetech-app.service could not be found.
```

Spring Bootを管理するsystemdのサービス定義が存在しませんでした。

さらに、アプリケーションログを確認しました。

```bash
sudo journalctl -u raisetech-app -n 80 --no-pager
```

**実行結果**

```text
-- No entries --
```

パッケージインストールが途中で失敗した結果、サービス登録処理まで進んでいないことと整合する結果でした。

### 4.5 8080番ポートの確認

**実行コマンド**

```bash
sudo ss -tlnp | grep ':8080'
```

**実行結果**

```text
（出力なし）
```

8080番ポートで待ち受けているプロセスは確認できませんでした。

続けて、EC2自身からHTTPアクセスを実施しました。

```bash
curl -i --max-time 5 http://127.0.0.1:8080/
```

**実行結果**

```text
curl: (7) Failed to connect to 127.0.0.1:8080
```

この結果から、少なくともEC2内部ではSpring Bootが8080番ポートで待ち受けていないことが確認できました。

### 4.6 調査結果の整理

| 調査項目 | 結果 | 判断 |
|---|---|---|
| EC2の稼働状態 | running | OSは起動している |
| cloud-init | error | User Dataが失敗 |
| cloud-init-output.log | パッケージ競合 | 失敗箇所を特定 |
| systemdサービス | 存在しない | サービス登録未完了 |
| アプリケーションログ | 記録なし | サービス未起動と整合 |
| 8080番ポート | 待ち受けなし | HTTP受付不可 |
| localhostへのHTTP接続 | 接続失敗 | アプリケーション未起動 |

これらの結果から、User Dataのパッケージインストール失敗が、アプリケーションを起動できなかった直接の原因であると特定しました。

## 5. 根本原因

User Dataのパッケージインストール処理に、次の指定が含まれていました。

**修正前**

```bash
dnf install -y \
  git \
  java-21-amazon-corretto-devel \
  mariadb105 \
  jq \
  curl \
  amazon-cloudwatch-agent
```

Amazon Linux 2023では、既に`curl-minimal`パッケージがインストールされており、必要な`curl`コマンドを利用できました。

しかし、追加で通常版`curl`をインストールしようとしたため、パッケージ競合が発生しました。

User Dataが`set -e`によって途中終了し、アプリケーションのビルドやsystemdサービスの登録処理まで進みませんでした。

**原因と影響の関係**

```text
Amazon Linux 2023
  │
  ▼
curl-minimalがインストール済み
  │
  ▼
User Dataでcurlを追加インストール
  │
  ▼
パッケージ競合によりdnf install失敗
  │
  ▼
set -eによってUser Dataが途中終了
  │
  ▼
Spring Bootの構築・起動処理が未実行
  │
  ▼
8080番ポートの待ち受けなし
  │
  ▼
ALBからのHTTP通信に失敗
  │
  ▼
HTTP 502・ターゲット異常・SNS通知
```

なお、今回の問題はTerraformのHCL構文そのものではなく、EC2の初期化スクリプトに含まれるパッケージ指定が実行環境と整合していなかったことによるものです。

## 6. 修正内容

### 6.1 User Dataの修正

対象ファイル：

`terraform/templates/user_data.sh.tftpl`

**修正後**

```bash
dnf install -y \
  git \
  java-21-amazon-corretto-devel \
  mariadb105 \
  jq \
  amazon-cloudwatch-agent
```

不要な`curl`の指定を削除しました。

エラーメッセージに表示されていた`--allowerasing`や`--skip-broken`は使用していません。

既にインストールされている`curl-minimal`で必要なコマンドを実行できるため、既存パッケージの置き換えや、失敗したパッケージのスキップを行う必要はないと判断しました。

### 6.2 TerraformでのEC2置換

Application ModuleのEC2リソースには、以下の設定を使用していました。

```hcl
user_data_replace_on_change = true
```

この設定により、User Dataの変更時にはEC2インスタンスが置換されます。

修正後にTerraform Planを実行しました。

**実行コマンド**

```bash
terraform plan -out=dev.tfplan
```

**実行結果**

```text
Plan: 2 to add, 2 to change, 2 to destroy.
```

**主な変更内容**

| リソース | 操作 | 理由 |
|---|---|---|
| EC2 | 置換 | User Dataの変更 |
| Target Group Attachment | 置換 | EC2のインスタンスID変更 |
| EC2 CPU Alarm | 更新 | 監視対象のEC2 ID変更 |
| CloudWatch Dashboard | 更新 | メトリクス参照先のEC2 ID変更 |

修正によってEC2と関連リソースのみが変更対象となり、VPCやRDSなどを一から再作成する必要はありませんでした。

### 6.3 再Apply

確認済みのPlanを使用して再Applyを実施しました。

```bash
terraform apply dev.tfplan
```

EC2が置換され、修正後のUser Dataが新しいインスタンスで実行されました。

## 7. 復旧確認

### 7.1 cloud-initの正常終了

**実行コマンド**

```bash
sudo cloud-init status --wait
sudo cloud-init status --long
```

**実行結果**

```text
status: done

detail:
DataSourceEc2
```

User Dataが最後まで正常に実行されたことを確認しました。

### 7.2 systemdサービスの状態

**実行コマンド**

```bash
sudo systemctl status raisetech-app --no-pager -l
```

**実行結果（抜粋）**

```text
Loaded: loaded (...; enabled; preset: disabled)
Active: active (running)
Main PID: 27221 (java)
```

Spring Bootがsystemdサービスとして起動していることを確認しました。

アプリケーションログには、次の内容が記録されていました。

```text
Tomcat started on port 8080 (http)
Started DemoApplication in 4.677 seconds
```

### 7.3 8080番ポートの確認

```bash
sudo ss -tlnp | grep ':8080'
```

**実行結果（抜粋）**

```text
LISTEN ... *:8080 ... users:(("java",pid=27221,...))
```

Javaプロセスが8080番ポートで待ち受けていることを確認しました。

### 7.4 EC2内部からのHTTP通信

```bash
curl -i --max-time 5 http://127.0.0.1:8080/
```

**実行結果**

```text
HTTP/1.1 200

受講生ID：1
受講生名：Kouji Enami
```

Spring BootからRDSへの接続も成功し、受講生情報を取得できました。

### 7.5 ALB Target Groupの確認

AWS CLIでTarget Groupの状態を確認しました。

**結果**

```text
Port: 8080
State: healthy
```

ALBが新しいEC2を正常なターゲットとして認識していることを確認しました。

### 7.6 ALB経由のHTTP通信

```bash
ALB_DNS=$(terraform output -raw alb_dns_name)

curl -i --max-time 10 "http://$ALB_DNS/"
```

**実行結果**

```text
HTTP/1.1 200

受講生ID：1
受講生名：Kouji Enami
```

**判定：復旧成功**

EC2の初期設定、Spring Bootの起動、RDS接続、ALB経由のHTTP通信まで正常動作を確認しました。

## 8. CloudWatch Alarmによる復旧確認

今回の障害では、CloudWatch Alarmに以下の状態遷移が記録されていました。

**実行コマンド**

```bash
aws cloudwatch describe-alarm-history \
  --alarm-name raisetech-tf-unhealthy-host \
  --history-item-type StateUpdate \
  --region ap-northeast-1 \
  --query 'AlarmHistoryItems[].{Time:Timestamp,Summary:HistorySummary}' \
  --output table
```

**実行結果**

| 時刻（JST） | 状態遷移 |
|---|---|
| 2026-11-21 15:09 | INSUFFICIENT_DATA → OK |
| 2026-11-21 15:19 | OK → ALARM |
| 2026-11-21 15:55 | ALARM → OK |

障害発生時にはSNSメール通知を受信しました。

修正後にはターゲットがHealthyとなり、アラームもOK状態へ復帰しました。

ALARM状態が継続していた時間は約36分です。

この時間はCloudWatch Alarmの状態遷移に基づくものであり、アプリケーションの正確な停止時間を示すものではありません。

## 9. Terraformの最終整合性確認

復旧後にTerraform Planを実行し、構成差分がないことを確認しました。

```bash
terraform plan
```

**実行結果**

```text
No changes. Your infrastructure matches the configuration.
```

さらに、Stateの管理対象を確認しました。

```bash
terraform state list | grep -vE '(^|\.)data\.' | wc -l
```

**実行結果**

```text
54
```

修正後も54リソースが管理対象であり、TerraformコードとAWS環境に意図しない差分がないことを確認しました。

検証終了後はTerraform Destroyによって54リソースを削除し、AWS上の残存リソースについても確認しました。

## 10. 再発防止策・改善案

今回の障害調査から、以下の改善点を整理しました。

| 改善項目 | 対応状況 | 内容 |
|---|---|---|
| 不要なcurlインストールの削除 | 対応済み | 既存のcurl-minimalを利用 |
| User Dataの正常終了確認 | 検証済み | cloud-initの状態を確認 |
| アプリケーション起動確認 | 実装済み | User Dataの最後でHTTP応答を確認 |
| Terraformによる再構築 | 検証済み | EC2置換と関連リソース更新 |
| User Dataの静的チェック | 今後の課題 | シェル構文や品質の検証を自動化 |
| EC2起動後の動作テスト | 今後の課題 | HTTPアクセスなどの検証を自動化 |
| AMIとパッケージの依存関係 | 今後の課題 | OS標準パッケージの事前確認 |
| アプリケーション取得バージョン | 今後の課題 | GitコミットSHAなどによる固定 |
| 可用性の向上 | 今後の課題 | Auto Scalingによる冗長化を検討 |

### 10.1 OS標準パッケージを確認する

パッケージを追加する前に、既に導入されているパッケージを確認することが重要です。

今回のような環境では、以下のコマンドが利用できます。

```bash
rpm -q curl-minimal
rpm -q curl
command -v curl
```

これらを利用して既存パッケージと必要なコマンドの有無を確認することで、不要なインストールを避けられます。

### 10.2 User Dataとアプリケーションの正常性を分けて確認する

EC2が`running`であっても、User Dataやアプリケーションが正常に動作しているとは限りません。

そのため、以下を区別して確認します。

1. EC2インスタンスの稼働状態
2. cloud-initの実行結果
3. systemdサービスの稼働状態
4. アプリケーションの待ち受けポート
5. ローカルHTTP通信
6. ALB経由のHTTP通信
7. CloudWatch Alarmの状態

これにより、問題が発生している範囲を段階的に絞り込めます。

### 10.3 Terraformでの修正・復旧手順を統一する

同様の障害が発生した場合も、手動でEC2の設定を変更するだけではなく、原因となるTerraformコードを修正して管理することを基本方針とします。

```text
障害検知
  ↓
ログ確認・原因調査
  ↓
Terraformコードの修正
  ↓
terraform validate
  ↓
terraform plan
  ↓
変更対象の確認
  ↓
terraform apply
  ↓
アプリケーションの動作確認
  ↓
terraform plan（No changes）
```

今回のような再構築可能な学習環境では、修正済みUser DataによるEC2置換が有効でした。

ただし、本番環境ではEC2の置換による停止時間やデータ消失の可能性を事前に評価する必要があります。

## 11. 今回の学び

今回の障害対応では、以下を実践しました。

- CloudWatch Alarmによる異常検知
- SNSメールによる障害通知
- ALBのHTTPステータスからの問題把握
- AWS CLIによるEC2の状態確認
- `cloud-init`によるUser Dataの実行状態確認
- ログからのパッケージ競合の特定
- `systemctl`によるサービス状態の確認
- `ss`による待ち受けポートの確認
- `curl`によるHTTP通信の切り分け
- Terraformコード修正とEC2の部分的な置換
- Spring Boot・RDS・ALBの復旧確認
- CloudWatch Alarmの正常状態への復帰確認
- Terraform Planによる最終的な構成整合性の確認

今回の経験から、Infrastructure as CodeでAWSリソースを作成できたことと、その上でアプリケーションが正常動作していることは別々に確認する必要があると学びました。

また、障害発生時には推測だけで設定を変更するのではなく、ログやサービスの状態から原因を切り分け、修正後も段階的に復旧を確認することの重要性を実感しました。

---

## 関連資料

- [Terraform README](../README.md)
- [動作検証記録](verification.md)
