
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
| cfn-lint | 個別スタック版7ファイル | 成功 |
| cfn-lint | Nested Stacks子テンプレート7ファイル | 成功 |
| cfn-lint | Nested Stacks親テンプレート1ファイル | 成功 |
| Guard test | RDS非公開ルール4件 | 成功 |
| Guard test | RDS暗号化ルール4件 | 成功 |
| Guard validate | RDS非公開設定 | PASS |
| Guard validate | RDSストレージ暗号化 | PASS |

GitHub Actionsで全Stepが正常終了することを確認した。

なお、Nested Stacksの親テンプレートについては、デプロイ前にローカルのTemplateURLをS3 URLへ変換する構成のため、`W3002`警告を除外して静的解析している。

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

CloudFormation Guardを使用し、Security GroupでSSH（TCP/22）が全世界に公開される設定を検出する。

また、CIDRを`!Ref`で参照している場合についても、参照先のパラメータ制約を確認することで、不適切な設定を検出できるようにする。

### 8.2 検証対象

- テンプレート：`templates/security.yaml`
- Guardルール：`guard/rules/sg-ssh.guard`
- 単体テスト：`guard/tests/sg-ssh_tests.yaml`
- ルール名：`NO_PUBLIC_SSH`

### 8.3 セキュリティルール

以下の条件に該当するSecurity Groupのインバウンド設定を検証する。

- プロトコルがTCPであること
- 許可ポート範囲に22番ポートが含まれること
- CIDRが`0.0.0.0/0`の場合はFAIL
- CIDRに`Ref`を使用する場合は、参照先と入力制約を確認する

今回の構成では、`Ref: MyIP`を許可対象とし、`MyIP`の定義が以下の条件を満たす場合にPASSとする。

- `Type`が`String`
- `AllowedPattern`が存在する
- `AllowedPattern`が指定したIPv4 `/32`制限の正規表現と完全一致する

それ以外の`Ref`や、入力制約が不足している場合はFAILとする。

### 8.4 CloudFormationのパラメータ制約

既存の`security.yaml`では、SSHの許可元を以下のように指定していた。

```yaml
CidrIp: !Ref MyIP
```

当初の`MyIP`は文字列型のパラメータであり、入力値の制限がなかった。

そのため、デプロイ時に`0.0.0.0/0`を指定できる状態だった。

これを改善するため、`MyIP`に`AllowedPattern`を追加し、有効なIPv4アドレスの`/32`形式のみを許可するよう変更した。

これにより、パラメータを使用する柔軟性を維持しながら、SSHの全IPv4アドレスへの公開を防止する制約を設けた。

### 8.5 Guardルールの改良過程

**① 初期ルール**

当初は`CidrIp == '0.0.0.0/0'`による直接比較のみ実施していた。

`Ref`を使ったテストケースを追加したところ、期待結果FAILに対し、実際にはPASSと判定された。

この結果から、直接比較だけでは`Ref`を使った危険な設定を見逃すことを確認した。

**② Refの検出を追加**

`CidrIp.'Ref' exists`による判定を追加し、SSHで`Ref`を使用する設定を検出するよう改良した。

単体テストは成功したが、実際の`security.yaml`では`CidrIp: !Ref MyIP`が検出され、validateがFAILになった。

**③ パラメータ制約の検証を追加**

`Ref`を一律に拒否するのではなく、`MyIP`に定義された`AllowedPattern`の内容を検証するルールへ改良した。

CloudFormation側にも入力制約を追加した結果、単体テストと実テンプレートの検証が成功した。

### 8.6 単体テスト

実行コマンド：

```bash
cfn-guard test \
  --rules-file guard/rules/sg-ssh.guard \
  --test-data guard/tests/sg-ssh_tests.yaml
```

| テストケース | 期待結果 | 結果 |
|---|---|---|
| restricted_ssh | PASS | 成功 |
| public_ssh | FAIL | 成功 |
| public_http | PASS | 成功 |
| public_port_range | FAIL | 成功 |
| no_security_group | SKIP | 成功 |
| public_ssh_using_ref | FAIL | 成功 |
| safe_ssh_using_ref | FAIL | 成功 |
| http_using_ref | PASS | 成功 |
| restricted_myip_ref | PASS | 成功 |
| myip_without_allowed_pattern | FAIL | 成功 |
| myip_with_unsafe_pattern | FAIL | 成功 |

**結果：11件すべて成功**

なお、`safe_ssh_using_ref`は参照先のデフォルト値が限定されたCIDRであっても、今回のルールで許可した`MyIP`の入力制約を満たしていないためFAILとなる。

### 8.7 実テンプレートの検証

実行コマンド：

```bash
cfn-guard validate \
  --rules guard/rules/sg-ssh.guard \
  --data templates/security.yaml \
  --type CFNTemplate \
  --show-summary all
```

検証結果：

```text
security.yaml Status = PASS
PASS rules
sg-ssh.guard/NO_PUBLIC_SSH    PASS
```

`cfn-lint -t templates/security.yaml`もエラー・警告なしで正常終了した。

### 8.8 GitHub Actionsによる自動検証

以下のStepにより自動検証を実施した。

- `Run Guard SSH tests`
- `Validate SSH security`

GitHub Actionsで両Stepが正常終了することを確認した。

RDSの8件とSSHの11件を合わせ、Guardの単体テストは合計19件となった。

### 8.9 検証範囲と制限事項

今回のSSHルールは、主に`AWS::EC2::SecurityGroup`の`SecurityGroupIngress`に定義されたTCP/22の設定を対象とする。

以下のケースについては、今回のルールで網羅的に検証できていない。

- IPv6の`::/0`による公開
- `IpProtocol: -1`による全プロトコル許可
- 独立した`AWS::EC2::SecurityGroupIngress`リソース
- `Fn::If`など、今回対応していない組み込み関数
- 実際のデプロイ先環境におけるネットワークの到達性

また、`AllowedPattern`の検証は今回定義した正規表現との完全一致を確認するものであり、任意の正規表現の安全性を判断するものではない。

今回のPASSは定義したルールへの適合を示しており、Security Group全体の安全性を保証するものではない。

## 9. まとめ

CloudFormation Guardを使用し、RDSの非公開設定、ストレージ暗号化、Security GroupのSSH公開制限という3種類のセキュリティ検証を実装した。

Guardの単体テスト19件を実施し、正常系・異常系ともに期待どおりの判定となることを確認した。

特にSSHの公開制限では、`!Ref`によるCIDR指定の検出漏れを確認し、パラメータの`AllowedPattern`を検証する方式へ改良した。

GitHub Actionsでは、15テンプレートの静的解析、19件のGuard単体テスト、3種類のセキュリティルールによるテンプレート検証が正常終了した。

これにより、CloudFormationテンプレートの構文・設定上の問題や、定義したセキュリティルールへの違反を、コード変更時に自動検出する仕組みを構築できた。

ただし、今回の検証対象には制限があり、稼働中のAWS環境全体の安全性や動作を保証するものではない。

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
