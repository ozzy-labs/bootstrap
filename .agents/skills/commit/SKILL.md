---
name: commit
description: 変更をステージし、Conventional Commits でコミットする。プッシュや PR 作成は行わない。
---

# commit - ステージング＆コミット

変更をステージし、Conventional Commits でコミットする。プッシュや PR 作成は行わない。

## 手順

### 1. 状態確認

以下のコマンドで現在の状態を把握する:

- `git status` で変更ファイルの一覧を取得
- `git diff` でステージされていない変更を確認
- `git diff --staged` でステージ済みの変更を確認
- `git log --oneline -5` で直近のコミット履歴を確認

変更がない場合、コミットする変更がない旨を伝えて終了する。

### 2. ステージング＆コミット

1. **ステージング:** 変更ファイルを個別に `git add <file>` でステージする。`.env` ファイルはステージングしない
2. **コミットメッセージ生成:** `.agents/skills/commit-conventions/SKILL.md` を参照し、ルールに従いメッセージを生成する
3. **コミット実行:** `git commit -m "<message>"`

### 3. 完了報告

実行結果を報告する:

```text
完了:
  コミット: abc1234 feat: add blog post
```
