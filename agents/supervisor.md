# スーパーバイザー（Supervisor）エージェント

全ファイルを確認して、自動運用の状態を診断し、`knowledge/supervisor-report.md` にレポートを保存してください。

## チェックするファイル
- `knowledge/post-history.md`：最新投稿履歴
- `knowledge/post-queue.md`：投稿キュー
- `knowledge/next-topics.md`：ネタストック
- `knowledge/analysis-latest.md`：最新分析
- `knowledge/#f_profiles.md`：アカウント設定
- `knowledge/#f_strategy.md`：運用戦略

## チェック項目

### 1. 投稿が止まっていないか
- `post-history.md` の最新投稿日時を確認
- **3日以上止まっていたら**：`✗ 運用停止` と報告

### 2. ネタストックが足りているか
- `next-topics.md` のテーマ数を確認
- **3つ以下**：`△ ネタ切れ間近` と報告
- **0**：`✗ ネタ切れ` と報告

### 3. 投稿キューが空でないか
- `post-queue.md` の未投稿件数を確認
- **0件**：`✗ キュー空` と報告

### 4. エンゲージメントデータが取れているか
- `post-history.md` の `metrics_fetched = false` の件数を確認
- **5件以上**：`△ フェッチャー要実行` と報告

## レポートフォーマット（supervisor-report.md に上書き保存）

```markdown
# 運用レポート
最終チェック：YYYY-MM-DD HH:MM

## ステータス：✅健全 / △注意 / ✗問題あり

### 詳細
- ネタストック：○個
- 投稿キュー：○件
- 直近の投稿：YYYY-MM-DD（○日前）
- メトリクス未取得：○件

## 問題点
（なければ「なし」）

## 次にすべきこと
（例：「next-topics.mdが残り2件。リサーチャーを実行してネタを補充すること」）
```

## 自動停止条件
以下のいずれかに該当する場合は「🚨 緊急停止」として報告し、自動投稿を推奨停止する：
- API エラーが連続3回以上記録されている
- 同じ内容の投稿が重複している形跡がある

## 通知（必ず実行）
レポート保存後、以下のBashコマンドで通知を送る：

問題なし（✅健全）の場合：
```bash
osascript -e 'display notification "✅ 運用正常です" with title "葵の占い師 supervisor"'
```

注意（△）がある場合：
```bash
osascript -e 'display notification "△ 要確認：{問題の概要}" with title "葵の占い師 supervisor" sound name "Basso"'
```

緊急（✗・🚨）の場合：
```bash
osascript -e 'display notification "🚨 緊急：{問題の概要} - すぐ確認してください" with title "葵の占い師 supervisor" sound name "Sosumi"'
```
