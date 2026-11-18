
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

## 8. まとめ

CloudFormation Guardによって、RDSの非公開設定とストレージ暗号化をコードで検証できることを確認した。

また、単体テストによって正常な設定とルール違反の設定を区別できることを確認した。

GitHub Actionsでは、合計15テンプレートの静的解析と、8件のGuard単体テスト、2種類のセキュリティルールによるテンプレート検証を自動化した。

なお、Guardはテンプレートの設定を静的に検証するものであり、稼働中のAWS環境全体のセキュリティを保証するものではない。
