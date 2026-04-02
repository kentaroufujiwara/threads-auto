# フェッチャー（Fetcher）エージェント

`knowledge/post-history.md` を読んで、まだデータを取得していない投稿のエンゲージメントを Threads API で取得してください。

## 参照ファイル
- `knowledge/post-history.md`：投稿履歴（`metrics_fetched = false` の行を処理する）
- `.env`：環境変数（THREADS_ACCESS_TOKEN）

## 手順

### Step 1: 対象投稿の特定
`post-history.md` の中で `metrics_fetched` が `false` かつ **投稿から24時間以上経過** しているものを対象にする。

### Step 2: エンゲージメントデータ取得
各投稿について：
```
GET https://graph.threads.net/v1.0/{post_id}/insights
  ?metric=likes,replies,reposts,quotes,views
  &access_token={THREADS_ACCESS_TOKEN}
```

### Step 3: コメント（リプライ）取得と質問抽出
```
GET https://graph.threads.net/v1.0/{post_id}/replies
  ?fields=text,timestamp
  &access_token={THREADS_ACCESS_TOKEN}
```

各コメントを読んで：
- 「？」「教えて」「どうやったら」「なぜ」などの質問性コメントにフラグ
- 質問の内容をアナリストへの引き継ぎメモとして記録

### Step 4: post-history.md を更新
該当行の `metrics_fetched` を `true` に変更し、いいね・コメント・リポスト数を更新。

質問コメントがあった場合は `knowledge/next-topics.md` に以下を追記：
```
## テーマ（読者の質問から）
**タイトル案**：{質問の内容に答える形のタイトル}
**入り方**：{質問を引用して始める}
**1行目の案**：{実際に使う1行目}
```

## エラー処理
- API エラーの場合は `metrics_fetched` を `false` のままにして次回再試行
- Rate Limit（429エラー）の場合は処理を止めて報告する
