---
name: commit-conventions
description: Conventional Commits のメッセージ生成ルール（Type/Scope 判定表、フォーマット）。他スキルから参照される。
---

# commit-conventions - コミットメッセージ生成ルール

Conventional Commits 1.0.0 に準拠する（commitlint で検証される）。

## Type の自動判定

| 変更内容 | Type |
|---------|------|
| 新機能の追加 | `feat` |
| バグ修正 | `fix` |
| ドキュメント変更 | `docs` |
| フォーマット（動作変更なし） | `style` |
| リファクタリング | `refactor` |
| パフォーマンス改善 | `perf` |
| テスト追加・修正 | `test` |
| ビルド・依存関係 | `build` |
| CI/CD 設定 | `ci` |
| その他 | `chore` |

## Scope の判定

変更が特定のディレクトリや機能に集中している場合、scope を付与する。ディレクトリ名や機能名から簡潔な scope を選ぶ:

- 例: `feat(blog):`, `fix(auth):`, `ci(deploy):`
- 複数ディレクトリにまたがる場合は scope を省略する

## メッセージ本文

- 1 行目: `type[(scope)]: description`（英語で、50 文字以内目安）
- 複数の論理的変更がある場合は body で補足

## 共通注意事項

- **force push は絶対に行わない**
- **.env ファイルは読み取り・ステージングしない**（`git add` 対象から除外）
- コミットメッセージの `Co-Authored-By` は付与しない（個人プロジェクトのため）
