# CloudFormation Guard セキュリティ検証

## 1. 目的

AWS CloudFormation Guardを使用し、CloudFormationテンプレートが定義したセキュリティルールに適合しているか検証する。

また、単体テストによって、ルールが期待どおりに判定することを確認する。

## 2. 検証対象

- テンプレート：`templates/database.yaml`
- ルールファイル：`guard/rules/rds.guard`
- テストファイル：`guard/tests/rds_tests.yaml`

## 3. セキュリティルール

ルール名：`RDS_NOT_PUBLIC`

- RDSの`PubliclyAccessible`が明示されていること
- `PubliclyAccessible`が`false`であること
- RDSが存在しない場合は検証をスキップすること

## 4. 単体テスト

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

**結果：全4件のテストが成功**

## 5. CloudFormationテンプレート検証

実行コマンド：

```bash
cfn-guard validate \
  --rules guard/rules/rds.guard \
  --data templates/database.yaml \
  --type CFNTemplate \
  --show-summary all
```

実行結果：

```text
templates/database.yaml Status = PASS

PASS rules
rds.guard/RDS_NOT_PUBLIC    PASS
```

**結果：PASS**

## 6. 検証から確認できたこと

- 正常な設定とルール違反の設定を正しく判定できた
- プロパティが未指定の場合もルール違反として検出できた
- 実際の`database.yaml`が定義したルールに適合していた

## 7. まとめ

CloudFormation Guardによって、CloudFormationテンプレートに対するセキュリティ基準をコード化し、デプロイ前に自動検証できることを確認した。

Guardの単体テストとテンプレート検証を組み合わせることで、ルール自体の正しさと、テンプレートのルール適合性をそれぞれ確認できた。

なお、今回の検証はRDSのパブリックアクセス設定に限定しており、AWS環境全体のセキュリティを保証するものではない。
