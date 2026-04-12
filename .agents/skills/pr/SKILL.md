---
name: pr
description: コミット済みの変更をリモートにプッシュし、PR を作成・更新する。
---

# pr - プッシュ＆PR 作成

コミット済みの変更をリモートにプッシュし、PR を作成・更新する。

## 前提条件

- main ブランチからの直接 push は行わない
- 未コミットの変更がある場合は先にコミットする
- プッシュ対象のコミットがない場合は終了する

## 手順

### 1. 状態確認

- `git branch --show-current` で現在のブランチを確認
- `git status` で未コミットの変更を確認
- `git log --oneline origin/<branch>..HEAD 2>/dev/null || git log --oneline -5` で未プッシュのコミットを確認

### 2. プッシュ＆PR 作成

1. `git push -u origin <branch>` でリモートにプッシュする
2. PR の作成:
   - `gh pr view` で既存 PR を確認する
   - **既存 PR がない場合:** `gh pr create --title "<タイトル>" --body "<本文>"` で PR を作成する。タイトルは直近のコミットメッセージの 1 行目を使用する
   - **既存 PR がある場合:** プッシュのみ（PR は自動更新される）

PR の本文フォーマット:

```markdown
## Summary

- <変更内容の箇条書き>

Closes #N <!-- Issue 起点の場合のみ -->
```

### 3. 完了報告

```text
完了:
  ブランチ: <branch-name>
  PR: <PR URL>
```
