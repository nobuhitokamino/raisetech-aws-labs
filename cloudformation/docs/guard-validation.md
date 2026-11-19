
# CloudFormation Guard セキュリティ検証

## 1. 目的

AWS CloudFormation Guardを使用し、CloudFormationテンプレートが定義したセキュリティルールに適合しているか検証する。

また、単体テストによってルールが期待どおりに動作することを確認し、GitHub Actionsによる自動検証を実施する。

## 2. 検証対象

- テンプレート：`templates/database.yaml`
- 非公開ルール：`guard/rules/rds.guard`
- 暗号化ルール：`guard/rules/rds-encryption.guard`
- 非公開ルールのテスト：`guard/tests/rds_tests.yaml`
- 暗号化ルールのテスト：`guard/tests/rds-encryption_tests.yaml`

## 3. セキュリティルール

### RDS_NOT_PUBLIC

RDSのパブリックアクセスを禁止するルール。

- `PubliclyAccessible`が明示されていること
- `PubliclyAccessible`が`false`であること
- RDSが存在しない場合はSKIPとする

### RDS_STORAGE_ENCRYPTED

RDSのストレージ暗号化を必須とするルール。

- `StorageEncrypted`が明示されていること
- `StorageEncrypted`が`true`であること
- RDSが存在しない場合はSKIPとする

## 4. 単体テスト

### RDS非公開ルール

実行コマンド：

```bash
cfn-guard test \
  --rules-file guard/rules/rds.guard \
  --test-data guard/tests/rds_tests.yaml
```

| テストケース | 期待結果 | 結果 |
|---|---|---|
| private_rds | PASS | 成功 |
| public_rds | FAIL | 成功 |
| missing_property | FAIL | 成功 |
| no_rds | SKIP | 成功 |

**結果：4件すべて成功**

### RDSストレージ暗号化ルール

実行コマンド：

```bash
cfn-guard test \
  --rules-file guard/rules/rds-encryption.guard \
  --test-data guard/tests/rds-encryption_tests.yaml
```

| テストケース | 期待結果 | 結果 |
|---|---|---|
| encrypted_rds | PASS | 成功 |
| unencrypted_rds | FAIL | 成功 |
| missing_encryption | FAIL | 成功 |
| no_rds | SKIP | 成功 |

**結果：4件すべて成功**

単体テストは合計8件実施し、すべて期待どおりの判定となった。

## 5. CloudFormationテンプレート検証

### RDS非公開設定の検証

```bash
cfn-guard validate \
  --rules guard/rules/rds.guard \
  --data templates/database.yaml \
  --type CFNTemplate \
  --show-summary all
```

結果：

```text
rds.guard/RDS_NOT_PUBLIC    PASS
```

### RDSストレージ暗号化の検証

```bash
cfn-guard validate \
  --rules guard/rules/rds-encryption.guard \
  --data templates/database.yaml \
  --type CFNTemplate \
  --show-summary all
```

結果：

```text
rds-encryption.guard/RDS_STORAGE_ENCRYPTED    PASS
```

**結果：2つのセキュリティルールに適合**

## 6. GitHub Actionsによる自動検証

GitHub ActionsでCloudFormationテンプレートの静的解析とGuardのセキュリティ検証を自動化した。

### CIの検証内容

| 検証項目 | 対象 | 結果 |
|---|---|---|
| cfn-lint | 個別スタック版7テンプレート | 成功 |
| cfn-lint | Nested Stacks子テンプレート7件 | 成功 |
| cfn-lint | Nested Stacks親テンプレート1件 | 成功 |
| Guard test | RDS非公開ルール4件 | 成功 |
| Guard test | RDS暗号化ルール4件 | 成功 |
| Guard test | SSH公開制限ルール26件 | 成功 |
| Guard validate | RDS非公開設定 | PASS |
| Guard validate | RDSストレージ暗号化 | PASS |
| Guard validate | SSH公開制限 | PASS |

GitHub Actionsにより、15テンプレートの静的解析、Guardの単体テスト34件、および3種類のセキュリティ検証が正常終了した。

Nested Stacksの親テンプレートについては、`aws cloudformation package`でローカルのTemplateURLをS3 URLへ変換する構成のため、`W3002`警告のみを除外して静的解析している。

## 7. CIの異常系テスト

RDS非公開ルールについて、GitHub Actionsがルール違反を正しく検出できるか確認した。

テスト用ブランチで`PubliclyAccessible`を一時的に`true`へ変更し、Pull Requestを作成した。

| 検証内容 | 結果 |
|---|---|
| 正常なRDS設定 | CI成功 |
| PubliclyAccessibleをtrueに変更 | GuardがFAILを検出 |
| ルール違反時のGitHub Actions | CI失敗 |
| falseに戻して再実行 | CI成功 |

違反時には`MyRDS`の`PubliclyAccessible`がルールに適合していないことをログから確認した。

検証後は正常な設定へ戻し、Pull Requestをmainへマージせずにクローズした。

[異常系テストのPull Request（#6）](https://github.com/nobuhitokamino/raisetech-aws-labs/pull/6)

※ストレージ暗号化ルールの異常系については、Guardの単体テストで検証している。

## 8. Security GroupのSSH公開制御検証

### 8.1 検証目的

CloudFormation Guardを使用し、Security GroupのSSH（TCP/22）が全世界に公開される設定を検出する。

IPv4・IPv6、全プロトコル許可、CloudFormationの異なるIngress定義方法、`Ref`によるパラメータ参照を対象とする。

### 8.2 検証対象

- テンプレート：`templates/security.yaml`
- Guardルール：`guard/rules/sg-ssh.guard`
- 単体テスト：`guard/tests/sg-ssh_tests.yaml`
- ルール名：`NO_PUBLIC_SSH`

検証対象となるCloudFormationリソースは以下の2種類。

1. `AWS::EC2::SecurityGroup`の`SecurityGroupIngress`
2. 独立した`AWS::EC2::SecurityGroupIngress`

### 8.3 セキュリティルール

以下の設定をルール違反として検出する。

| プロトコル・ポート | IPv4 | IPv6 |
|---|---|---|
| TCP/22を含むポート範囲 | `0.0.0.0/0`は禁止 | `::/0`は禁止 |
| 全プロトコル許可（-1） | `0.0.0.0/0`は禁止 | `::/0`は禁止 |

これらの条件は、Security Group内部のIngressと独立したIngressリソースの両方に適用する。

また、IPv4のSSH許可元に`Ref`を使用する場合は、以下の条件を確認する。

- 参照先は`MyIP`であること
- `MyIP`の`Type`が`String`であること
- `AllowedPattern`が存在すること
- `AllowedPattern`が定義済みのIPv4 `/32`制限の正規表現と完全一致すること

条件を満たさないパラメータ参照はFAILとする。

### 8.4 CloudFormationパラメータの制約

`security.yaml`では、SSHの許可元を次のように指定している。

```yaml
CidrIp: !Ref MyIP
```

当初の`MyIP`には入力値の制約がなく、`0.0.0.0/0`も指定できる状態だった。

この問題に対して`AllowedPattern`を追加し、IPv4の単一アドレスを示す`/32`形式に制限した。

Guard側では、この入力制約が期待する正規表現と完全一致することを確認する。

### 8.5 ルールの改良過程

以下の順序で検出漏れを確認し、ルールを拡張した。

| 段階 | 発見した問題 | 対応内容 |
|---|---|---|
| 1 | `Ref`によるCIDR指定を見逃す | `Ref`の検出とパラメータ制約の確認を追加 |
| 2 | IPv6のSSH公開を見逃す | `CidrIpv6: ::/0`を検出 |
| 3 | `IpProtocol: '-1'`を見逃す | IPv4・IPv6の全プロトコル公開を検出 |
| 4 | 独立したIngressを見逃す | `AWS::EC2::SecurityGroupIngress`を検証対象に追加 |
| 5 | 独立IngressのIPv6・全プロトコルを見逃す | それぞれの検出条件を追加 |
| 6 | 独立Ingressの`Ref`を見逃す | `MyIP`の参照と入力制約の検証を追加 |

各段階で、まず既存ルールの検出漏れを単体テストで確認した。

その後、Guardルールを修正して再テストし、期待どおりの判定になることを確認した。

### 8.6 単体テスト

実行コマンド：

```bash
cfn-guard test \
  --rules-file guard/rules/sg-ssh.guard \
  --test-data guard/tests/sg-ssh_tests.yaml
```

| No. | テストケース | 期待結果 | テスト結果 |
|---|---|---|---|
| 1 | restricted_ssh | PASS | 成功 |
| 2 | public_ssh | FAIL | 成功 |
| 3 | public_http | PASS | 成功 |
| 4 | public_port_range | FAIL | 成功 |
| 5 | no_security_group | SKIP | 成功 |
| 6 | public_ssh_using_ref | FAIL | 成功 |
| 7 | safe_ssh_using_ref | FAIL | 成功 |
| 8 | http_using_ref | PASS | 成功 |
| 9 | restricted_myip_ref | PASS | 成功 |
| 10 | myip_without_allowed_pattern | FAIL | 成功 |
| 11 | myip_with_unsafe_pattern | FAIL | 成功 |
| 12 | public_ssh_ipv6 | FAIL | 成功 |
| 13 | restricted_ssh_ipv6 | PASS | 成功 |
| 14 | public_http_ipv6 | PASS | 成功 |
| 15 | public_all_protocols_ipv4 | FAIL | 成功 |
| 16 | public_all_protocols_ipv6 | FAIL | 成功 |
| 17 | standalone_public_ssh_ipv4 | FAIL | 成功 |
| 18 | standalone_only_public_ssh | FAIL | 成功 |
| 19 | standalone_public_ssh_ipv6 | FAIL | 成功 |
| 20 | standalone_all_protocols_ipv4 | FAIL | 成功 |
| 21 | standalone_all_protocols_ipv6 | FAIL | 成功 |
| 22 | standalone_restricted_ssh_ipv4 | PASS | 成功 |
| 23 | standalone_public_http | PASS | 成功 |
| 24 | standalone_ssh_using_unrestricted_ref | FAIL | 成功 |
| 25 | standalone_restricted_myip_ref | PASS | 成功 |
| 26 | standalone_unsupported_ref | FAIL | 成功 |

**結果：26件すべて成功**

テストでは、正常な設定をPASS、不適切な設定をFAIL、対象リソースがない場合をSKIPとして、期待どおりに判定されることを確認した。

なお、`Ref`によるCIDR指定は実際の参照値を解決しているわけではない。

今回のルールでは、許可した参照先とパラメータ制約の条件を満たすかを検証している。

### 8.7 実テンプレートの検証

実行コマンド：

```bash
cfn-guard validate \
  --rules guard/rules/sg-ssh.guard \
  --data templates/security.yaml \
  --type CFNTemplate \
  --show-summary all
```

結果：

```text
security.yaml Status = PASS
PASS rules
sg-ssh.guard/NO_PUBLIC_SSH    PASS
```

ルール拡張後も、既存テンプレートが定義したセキュリティ条件に適合していることを確認した。

### 8.8 GitHub Actionsによる自動検証

以下のStepでSSHルールの単体テストとテンプレート検証を自動実行する。

- `Run Guard SSH tests`
- `Validate SSH security`

GitHub Actionsでは、SSHの単体テスト26件と実テンプレート検証が正常終了した。

RDSの単体テスト8件と合わせ、Guardの単体テストは合計34件となった。

### 8.9 検証範囲と制限事項

今回のルールは、IPv4・IPv6の全世界公開、全プロトコル許可、2種類のIngress定義方法を対象としている。

ただし、以下の指定方法などは網羅的に検証できていない。

- IPv6のCIDRを`Ref`で指定する場合
- `Fn::If`や`Fn::Sub`などの組み込み関数による指定
- 今回の条件以外の動的なプロトコル・ポート指定
- 許可されたCIDRが実際にどの接続元を表しているか
- 稼働中のAWS環境における実際の到達性

また、`AllowedPattern`の検証は指定した正規表現との完全一致を確認するものであり、任意の正規表現の安全性を評価するものではない。

今回のPASSは、定義したGuardルールへの適合を示すものであり、Security Group全体の安全性を保証するものではない。

## 9. まとめ

CloudFormation Guardを使用し、RDSの非公開設定、ストレージ暗号化、Security GroupのSSH公開制限という3種類のセキュリティルールを実装した。

RDSの8件とSSHの26件を合わせ、合計34件の単体テストを実施し、すべて期待どおりの判定となることを確認した。

SSH公開制限では、IPv4・IPv6、全プロトコル許可、独立したIngressリソース、`Ref`によるCIDR指定を対象に検証範囲を拡張した。

検出漏れを単体テストで確認し、ルールを改良して再検証することで、テストによってルールの動作を確認する手順を実践した。

GitHub Actionsでは、15テンプレートの静的解析、34件のGuard単体テスト、3種類のセキュリティ検証が正常終了した。

これにより、CloudFormationテンプレートの静的解析と、定義したセキュリティルールへの適合確認を自動実行するCI環境を構築した。

なお、検証対象には制限があり、稼働中のAWS環境全体の安全性や動作を保証するものではない。

## 10. CI実行時のトラブルシューティング

### 10.1 CloudFormation Guardのインストール失敗

**発生した問題**

GitHub ActionsでCloudFormation Guardのインストール処理中にHTTP 403エラーが発生した。

その結果、後続Stepで`cfn-guard: command not found`となり、CIが失敗した。

**原因調査**

GitHubからのダウンロード要求が拒否されていた。

GitHub APIのアクセス制限などが考えられるが、403エラーの詳細な原因は特定できていない。

**対処内容**

- GitHub CLI（gh）を利用するインストール方法へ変更
- GitHub Actionsのトークンを利用して認証
- CloudFormation Guardのバージョンを3.2.2に固定

**結果**

修正後のGitHub ActionsでGuardのインストールと全検証Stepが正常終了した。
