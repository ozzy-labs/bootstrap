---
name: drive
description: Issue から実装・PR 作成・セルフレビュー・修正を自動で回し、merge-ready な PR を出す。Issue 番号またはテキスト指示を受け取る。
---

# drive - Issue から merge-ready な PR まで自律駆動

Issue または指示を受け取り、実装 → ship → セルフレビュー → 修正を自動で繰り返して merge-ready な PR を作成する。マージはユーザーの明示的な指示まで行わない。

## ワークフロー

### Phase 1: implement

implement スキルのワークフローを実行する。ただし以下の点が異なる:

- **計画承認をスキップ:** drive を実行した時点でユーザーは自律実行を委任しているため、計画を自ら承認して実装を進める
- **完了報告・次のアクション確認は無視:** フェーズ間の遷移は本スキルが制御する

**中断条件:** 動作確認が繰り返し失敗する場合 → エラーを報告して中断

### Phase 2: ship

ship スキルのワークフロー（lint → commit → PR 作成）を実行する。完了報告・次のアクション確認は無視する。

- PR 番号を記録する（Phase 3 で使用）

**中断条件:** lint が失敗し、自動修正できない場合 → エラーを報告して中断

### Phase 3: review loop（最大 3 回）

以下のループを最大 3 回繰り返す:

1. **レビュー実行:** review スキルで PR をレビューし、結果を PR コメントとして投稿する
2. **判定:**
   - Critical または Warning が 0 件 → ループを終了
   - Critical または Warning がある場合 → 修正に進む
   - ループ上限（3 回）に到達 → ループを終了（残存指摘を報告に含める）
3. **修正:** Critical および Warning の指摘事項のみを修正する。Info は修正しない（報告のみ）。修正後、lint → commit → push を実行し、1 に戻る

### Phase 4: 完了報告

```text
drive 完了:
  Issue:    #<number> <title>
  ブランチ: <branch-name>
  PR:       <PR URL>
  レビュー: N 回実施（Critical: 0, Warning: 0, Info: N）
  状態:     merge-ready
```

## 注意事項

- .env ファイルは読み取り・ステージングしない
- `gh` CLI が未認証の場合はエラーメッセージを表示して中断する
- マージはユーザーの明示的な指示がない限り実行しない
- Info 指摘は修正せず報告のみ（設計判断に関わる変更を機械的に行わない）
