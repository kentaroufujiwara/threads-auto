#!/bin/bash
# poster.sh - post-queue.md の先頭投稿を Threads API で直接投稿する
# claudeコマンド不要・curlのみで動作

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
QUEUE_FILE="${SCRIPT_DIR}/knowledge/post-queue.md"
HISTORY_FILE="${SCRIPT_DIR}/knowledge/post-history.md"
ENV_FILE="${SCRIPT_DIR}/.env"

# .env 読み込み
source "${ENV_FILE}"

# ── 1. キューから先頭ブロックを取得 ──────────────────────────
# HTMLコメント(<!--...-->)をスキップして最初の ---...--- ブロックを抽出
BLOCK=$(python3 - "${QUEUE_FILE}" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# HTMLコメントを除去
content_no_comment = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)

# 最初の ---\n...\n--- ブロックを抽出
match = re.search(r'\n---\n(.*?)\n---\n', content_no_comment, re.DOTALL)
if match:
    print(match.group(1).strip())
PYEOF
)

if [ -z "$BLOCK" ]; then
  echo "⚠️ post-queue.md に投稿がありません"
  exit 0
fi

# ── 2. 本文とコメントを抽出 ──────────────────────────────────
# 「本文: |」〜「コメント: |」または「作成日時:」までを本文として取得
TEXT=$(echo "$BLOCK" | awk '
  /^本文: \|/{in_text=1; next}
  /^コメント: \|/{in_text=0}
  /^作成日時:/{in_text=0}
  in_text{
    sub(/^  /, "")  # 先頭2スペースを除去
    print
  }
')

COMMENT=$(echo "$BLOCK" | awk '
  /^コメント: \|/{in_comment=1; next}
  /^作成日時:/{in_comment=0}
  in_comment{
    sub(/^  /, "")
    print
  }
')

if [ -z "$TEXT" ]; then
  echo "⚠️ 本文が空です"
  exit 1
fi

echo "📝 投稿内容："
echo "$TEXT" | head -3
echo "..."

# ── 3. 今日の投稿数チェック（5本上限） ───────────────────────
TODAY=$(date +%Y-%m-%d)
TODAY_COUNT=$(grep -c "$TODAY" "${HISTORY_FILE}" 2>/dev/null || echo 0)
if [ "$TODAY_COUNT" -ge 5 ]; then
  echo "⚠️ 本日すでに5本投稿済み。BAN防止のため停止。"
  exit 0
fi

# ── 4. Threads API でテキストコンテナ作成 ────────────────────
echo "📡 Threads API: コンテナ作成中..."
CONTAINER_RESULT=$(curl -s -X POST "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads" \
  -d "media_type=TEXT" \
  --data-urlencode "text=${TEXT}" \
  -d "access_token=${THREADS_ACCESS_TOKEN}")

CREATION_ID=$(echo "$CONTAINER_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)

if [ -z "$CREATION_ID" ]; then
  echo "❌ コンテナ作成失敗: ${CONTAINER_RESULT}"
  exit 1
fi

echo "✅ コンテナID: ${CREATION_ID}"

# ── 5. 投稿を公開 ────────────────────────────────────────────
sleep 3  # API安定待ち

echo "📡 Threads API: 公開中..."
PUBLISH_RESULT=$(curl -s -X POST "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads_publish" \
  -d "creation_id=${CREATION_ID}" \
  -d "access_token=${THREADS_ACCESS_TOKEN}")

POST_ID=$(echo "$PUBLISH_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)

if [ -z "$POST_ID" ]; then
  echo "❌ 公開失敗: ${PUBLISH_RESULT}"
  exit 1
fi

echo "✅ 投稿完了: post_id=${POST_ID}"

# ── 6. セルフリプライ（コメントがある場合） ─────────────────
if [ -n "$COMMENT" ]; then
  sleep 5
  echo "📡 セルフリプライ投稿中..."
  REPLY_CONTAINER=$(curl -s -X POST "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads" \
    -d "media_type=TEXT" \
    --data-urlencode "text=${COMMENT}" \
    -d "reply_to_id=${POST_ID}" \
    -d "access_token=${THREADS_ACCESS_TOKEN}")

  REPLY_CREATION_ID=$(echo "$REPLY_CONTAINER" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)

  if [ -n "$REPLY_CREATION_ID" ]; then
    sleep 3
    curl -s -X POST "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads_publish" \
      -d "creation_id=${REPLY_CREATION_ID}" \
      -d "access_token=${THREADS_ACCESS_TOKEN}" > /dev/null
    echo "✅ セルフリプライ完了"
  fi
fi

# ── 7. post-queue.md から先頭ブロックを削除 ──────────────────
python3 - "${QUEUE_FILE}" <<'EOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# HTMLコメントブロックを除去（長さが変わることに注意）
comments = list(re.finditer(r'<!--.*?-->', content, flags=re.DOTALL))

# コメント除去後のテキストで先頭ブロックを特定
no_comment = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
m = re.search(r'\n---\n.*?\n---\n', no_comment, re.DOTALL)
if not m:
    print("⚠️ 削除対象ブロックが見つかりません")
    sys.exit(0)

# no_comment上の位置を元content上の位置に変換
# コメントブロックの分だけオフセットを加算する
offset = 0
for c in comments:
    if c.start() <= m.start() + offset:
        offset += len(c.group())
    else:
        break

orig_start = m.start() + offset
orig_end = m.end() + offset

# 元contentで同じ範囲を削除
content = content[:orig_start] + '\n' + content[orig_end:]

with open(path, 'w') as f:
    f.write(content)

print("✅ キューから削除完了")
EOF

# ── 8. post-history.md に記録 ─────────────────────────────────
NOW=$(date +"%Y-%m-%d %H:%M")
TEXT_PREVIEW=$(echo "$TEXT" | head -1 | cut -c1-50)
echo "| ${POST_ID} | ${NOW} | ${TEXT_PREVIEW}... | 0 | 0 | 0 | false |" >> "${HISTORY_FILE}"
echo "✅ post-history.md に記録完了"

echo ""
echo "🎉 投稿処理完了！"
