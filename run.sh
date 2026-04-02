#!/bin/bash
# Threads 自動運用 実行スクリプト
# 使い方: ./run.sh [agent名]
#
# 利用可能なエージェント:
#   writer      - next-topics.md からテーマを選んで投稿文を生成
#   poster      - post-queue.md の先頭投稿を実際に投稿
#   researcher  - YouTube・X・Webからネタを収集
#   analyst     - 投稿データを分析して次のテーマを提案
#   fetcher     - 投稿のエンゲージメントデータを取得
#   supervisor  - 全体の健全性をチェック
#   commenter   - ベンチマーク投稿のリプ欄を参考にコメント（1日5件上限）
#   all         - writer → poster を順番に実行（1日の運用）

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DIR="${SCRIPT_DIR}/agents"

# .env を読み込む
if [ -f "${SCRIPT_DIR}/.env" ]; then
  export $(grep -v '^#' "${SCRIPT_DIR}/.env" | xargs)
fi

run_agent() {
  local agent=$1
  local prompt_file="${AGENTS_DIR}/${agent}.md"

  if [ ! -f "$prompt_file" ]; then
    echo "❌ エージェントが見つかりません: ${agent}"
    exit 1
  fi

  echo "🤖 ${agent} を実行中..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Claude Code (claude CLI) でエージェントを実行
  # --allowedTools でファイル読み書きとネットワークアクセスを許可
  /Users/fujiwarakentarou/.local/bin/claude \
    --print \
    --allowedTools "Read,Write,Edit,Bash,WebFetch,WebSearch" \
    --add-dir "${SCRIPT_DIR}" \
    "$(cat "${prompt_file}")"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ ${agent} 完了"
  echo ""
}

# 引数チェック
AGENT="${1:-}"

case "$AGENT" in
  poster)
    cd "${SCRIPT_DIR}"
    echo "🤖 poster を実行中（シェルスクリプト直接実行）..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "${SCRIPT_DIR}/scripts/poster.sh"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ;;
  writer|researcher|analyst|fetcher|supervisor|commenter)
    cd "${SCRIPT_DIR}"
    run_agent "$AGENT"
    ;;
  all)
    cd "${SCRIPT_DIR}"
    echo "🚀 1日の自動運用を開始します..."
    echo ""
    run_agent "writer"
    bash "${SCRIPT_DIR}/scripts/poster.sh"
    echo "🎉 本日の投稿完了！"
    ;;
  test)
    bash "${SCRIPT_DIR}/scripts/test-api.sh"
    ;;
  supervisor-check)
    cd "${SCRIPT_DIR}"
    run_agent "supervisor"
    cat "${SCRIPT_DIR}/knowledge/supervisor-report.md"
    ;;
  "")
    echo "Threads 自動運用システム"
    echo ""
    echo "使い方: ./run.sh [コマンド]"
    echo ""
    echo "コマンド一覧:"
    echo "  writer       投稿文を1件生成して post-queue.md に追加"
    echo "  poster       post-queue.md の先頭を Threads に投稿"
    echo "  researcher   YouTube・X・Webからネタを収集"
    echo "  analyst      投稿データを分析してテーマを提案"
    echo "  fetcher      エンゲージメントデータを取得"
    echo "  supervisor   運用状況をチェックしてレポート出力"
    echo "  all          writer → poster を順番実行（毎日3回実行推奨）"
    echo "  test         Threads API 接続テスト"
    echo ""
    echo "初回セットアップ:"
    echo "  1. cp .env.example .env"
    echo "  2. .env にアクセストークンとユーザーIDを記入"
    echo "  3. ./run.sh test  で接続確認"
    echo "  4. knowledge/#f_profiles.md でジャンル・ペルソナを設定"
    echo "  5. knowledge/next-topics.md にネタを追加"
    echo "  6. ./run.sh writer  で最初の投稿文を生成"
    echo "  7. ./run.sh poster  で投稿！"
    ;;
  *)
    echo "❌ 不明なコマンド: ${AGENT}"
    echo "   ./run.sh で使い方を確認してください"
    exit 1
    ;;
esac
