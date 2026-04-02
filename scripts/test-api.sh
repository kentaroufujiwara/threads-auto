#!/bin/bash
# Threads API 接続テストスクリプト
# 実行前に .env を設定してください

set -e

# .env を読み込む
if [ -f "$(dirname "$0")/../.env" ]; then
  export $(grep -v '^#' "$(dirname "$0")/../.env" | xargs)
else
  echo "❌ .env ファイルが見つかりません"
  echo "   .env.example をコピーして設定してください"
  exit 1
fi

if [ -z "$THREADS_ACCESS_TOKEN" ] || [ -z "$THREADS_USER_ID" ]; then
  echo "❌ THREADS_ACCESS_TOKEN または THREADS_USER_ID が未設定です"
  exit 1
fi

echo "🔍 Threads API 接続テスト中..."
echo ""

# プロフィール情報取得テスト
echo "1️⃣  プロフィール取得テスト..."
PROFILE=$(curl -s "https://graph.threads.net/v1.0/${THREADS_USER_ID}?fields=id,username,name&access_token=${THREADS_ACCESS_TOKEN}")

if echo "$PROFILE" | grep -q '"id"'; then
  USERNAME=$(echo "$PROFILE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('username','不明'))")
  echo "   ✅ 接続成功！ アカウント名: @${USERNAME}"
else
  echo "   ❌ 接続失敗: $PROFILE"
  exit 1
fi

echo ""
echo "2️⃣  テスト投稿（コンテナ作成のみ、実際には投稿しません）..."
TEST_CONTAINER=$(curl -s -X POST \
  "https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads" \
  -d "media_type=TEXT" \
  --data-urlencode "text=【テスト】API接続確認用のテスト投稿です。自動化システムの設定中。" \
  -d "access_token=${THREADS_ACCESS_TOKEN}")

if echo "$TEST_CONTAINER" | grep -q '"id"'; then
  CONTAINER_ID=$(echo "$TEST_CONTAINER" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
  echo "   ✅ コンテナ作成成功！ ID: ${CONTAINER_ID}"
  echo ""
  echo "   💡 このコンテナIDで実際に投稿する場合は以下を実行："
  echo "   curl -X POST 'https://graph.threads.net/v1.0/${THREADS_USER_ID}/threads_publish?creation_id=${CONTAINER_ID}&access_token=${THREADS_ACCESS_TOKEN}'"
else
  echo "   ❌ コンテナ作成失敗: $TEST_CONTAINER"
  exit 1
fi

echo ""
echo "✅ API接続テスト完了！自動投稿の準備ができています。"
