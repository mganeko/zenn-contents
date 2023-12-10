---
title: "スマホのカメラに映る景色を音声で案内する Visual Sonar の試作" # 記事のタイトル
emoji: "📷" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["GPT4-V"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---


# メモ

## 全体構成

- getUserMedia() を使って、カメラの映像を取得
- Video要素、Canvas要素を使って、画像を取得
- GPT-4 vision を使って、画像の内容を解析
- Viode API を使って、text-to-speech で読み上げ
- Audio要素で再生

