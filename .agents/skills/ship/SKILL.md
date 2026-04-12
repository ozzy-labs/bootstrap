---
name: ship
description: lint・コミット・PR 作成を一括実行する。変更に対して lint → コミット → PR 作成を順に実行する統合パイプライン。
---

# ship - lint・コミット・PR を一括実行

変更に対して lint → コミット → PR 作成を順に実行する統合パイプライン。いずれかのステップで失敗した場合は中断し、エラー内容を報告する。

## 手順

### Step 1: lint

1. `git status` で変更ファイルを特定する
2. `.agents/skills/lint-rules/SKILL.md` を参照し、対象ファイルの lint・フォーマット・型チェックを実行する
3. エラーがある場合は報告して中断する

### Step 2: commit

1. `git status` で変更ファイルの一覧を取得する
2. 変更ファイルを個別に `git add <file>` でステージする。`.env` ファイルはステージングしない
3. `.agents/skills/commit-conventions/SKILL.md` を参照し、Conventional Commits に従いコミットメッセージを生成する
4. `git commit -m "<message>"` でコミットする

変更がない場合、既にコミット済みの未プッシュコミットがあれば Step 3 に進む。なければ終了する。

### Step 3: pr

1. `git branch --show-current` で現在のブランチを確認する（main の場合は中断）
2. `git push -u origin <branch>` でリモートにプッシュする
3. `gh pr view` で既存 PR を確認する
   - 既存 PR がない場合: `gh pr create --title "<タイトル>" --body "<本文>"` で作成
   - 既存 PR がある場合: プッシュのみ（PR は自動更新）

### Step 4: 完了報告

```text
完了:
  コミット: abc1234 feat: add blog post
  ブランチ: feat/add-blog
  PR: <PR URL>
```
