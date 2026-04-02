# ポスター（Poster）エージェント

`knowledge/post-queue.md` の一番上の投稿を Threads API で投稿してください。

## 参照ファイル
- `knowledge/post-queue.md`：投稿キュー（先頭の投稿を処理する）
- `knowledge/ban-rules.md`：BANリスク回避ルール（**必ず最初に読む**）
- `knowledge/post-history.md`：投稿済み履歴（追記する・直近5件と内容重複チェック）
- `.env`：環境変数（THREADS_ACCESS_TOKEN、THREADS_USER_ID）

## 手順

### Step 1: post-queue.md を読む
`post-queue.md` の一番上の `---` ブロックを取得する。

### Step 2: 最終チェック
`ban-rules.md` を読んで、以下を確認：
- 500文字以内か
- NGワード（「必ず当たる」「100%」「不幸になる」など）が含まれていないか
- post-history.mdの直近5件と内容・書き出しが被っていないか
- 今日すでに5本以上投稿していないか（post-history.mdで確認）
- APIエラーが直近で連続していないか

問題があれば投稿せずに警告を出す。

### Step 3: Threads API で投稿
**テキストコンテナ作成：**
```
POST https://graph.threads.net/v1.0/{THREADS_USER_ID}/threads
  ?media_type=TEXT
  &text={投稿テキスト（URLエンコード）}
  &access_token={THREADS_ACCESS_TOKEN}
```

**投稿を公開：**
```
POST https://graph.threads.net/v1.0/{THREADS_USER_ID}/threads_publish
  ?creation_id={上で取得したID}
  &access_token={THREADS_ACCESS_TOKEN}
```

**セルフリプライ（コメントがある場合）：**
```
POST https://graph.threads.net/v1.0/{THREADS_USER_ID}/threads
  ?media_type=TEXT
  &text={コメントテキスト}
  &reply_to_id={投稿ID}
  &access_token={THREADS_ACCESS_TOKEN}
```
→ 同様に threads_publish で公開

### Step 4: 完了後の処理
1. `post-queue.md` から投稿済みのブロック（`---` 〜 `---`）を削除
2. `post-history.md` に以下の形式で追記：
   ```
   | {post_id} | {投稿日時} | {本文先頭50文字}... | 0 | 0 | 0 | false |
   ```

## エラー処理
- APIエラーが出たら**リトライしない**（二重投稿防止）
- エラー内容をログに残して処理を止める
- 1回の実行で1投稿のみ処理する（絶対厳守）
