# Threads 自動運用システム（Claude Code × Threads API）

Claude Code CLI を使って Threads への投稿を完全自動化するテンプレートです。
**2ファイルを書き換えるだけで、どんなジャンルにも使えます。**

---

## 仕組み

```
cron（定時起動）
    ↓
run.sh（エージェント振り分け）
    ↓
agents/*.md（Claudeへの指示書）
    ↓
claude --print（AIが実行）
    ↓
knowledge/*.md（ファイルで情報を受け渡し）
    ↓
Threads API（curl で投稿）
```

エージェント同士はファイルで会話します。AIに記憶がなくてもファイルが記憶を持つので、完全自動で回り続けます。

---

## エージェント構成

| エージェント | 役割 |
|------------|------|
| `researcher` | WebでネタをリサーチしてキューにテーマをためるResercher |
| `writer` | テーマから投稿文を生成してキューに追加 |
| `poster` | キューの先頭をThreads APIで投稿（シェルスクリプト・claude不要） |
| `commenter` | ベンチマーク投稿のリプ欄を参考にコメント活動 |
| `analyst` | 反応データを分析して戦略を更新 |
| `supervisor` | 全体の健全性チェック・macOS通知 |

---

## セットアップ

### 1. 必要なもの
- macOS（cronが使えれば他のOSでも可）
- [Claude Code CLI](https://claude.ai/code)（`claude` コマンド）
- Threads APIアクセストークン（[Meta Developer](https://developers.facebook.com/)で取得）

### 2. インストール

```bash
git clone https://github.com/YOUR_USERNAME/threads-auto.git
cd threads-auto
cp .env.example .env
```

### 3. .env を編集

```
THREADS_ACCESS_TOKEN=your_token_here
THREADS_USER_ID=your_user_id_here
```

### 4. アカウント設定（ここだけ書き換える）

**`knowledge/#f_profiles.md`** にアカウントのコンセプト・口調・ターゲットを記入

**`knowledge/#f_strategy.md`** に運用戦略・ベンチマークアカウントを記入

### 5. 初期キューを作成

```bash
./run.sh writer
```

### 6. 動作テスト

```bash
./run.sh poster
```

### 7. cron に登録（毎日3投稿）

```bash
crontab -e
```

以下を追加（`claude`のパスは `which claude` で確認）：

```
0 7 * * *    cd /path/to/threads-auto && ./run.sh poster
0 11 * * *   cd /path/to/threads-auto && ./run.sh researcher
30 11 * * *  cd /path/to/threads-auto && ./run.sh writer
0 12 * * *   cd /path/to/threads-auto && ./run.sh poster
30 12 * * *  cd /path/to/threads-auto && ./run.sh commenter
0 20 * * *   cd /path/to/threads-auto && ./run.sh writer
30 20 * * *  cd /path/to/threads-auto && ./run.sh poster
0 21 * * *   cd /path/to/threads-auto && ./run.sh commenter
0 22 * * *   cd /path/to/threads-auto && ./run.sh supervisor
```

> **macOS の注意：** システム環境設定 → プライバシーとセキュリティ → フルディスクアクセスに `/usr/sbin/cron` を追加してください。

---

## カスタマイズ

`agents/*.md` はClaudeへの指示書です。普通の日本語で書き換えるだけで動作が変わります。

---

## BAN防止ルール

`knowledge/ban-rules.md` に記載。主なルール：
- 1日の投稿上限：5本
- 投稿間隔：30分以上
- コメント：1日5件・同アカウント1日1件まで
- APIエラー時リトライなし

---

## ライセンス

MIT
