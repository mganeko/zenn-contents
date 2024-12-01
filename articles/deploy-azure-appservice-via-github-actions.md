---
title: "ハッカソで学んだGitHub ActionsでAzure App Seriveにデプロイする手順" # 記事のタイトル
emoji: "☁" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["Azure", "githubactions", "Actions"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

この記事は非公式の[Infocom Advent Calendar 2024](https://qiita.com/advent-calendar/2024/infocom)のx日目の記事です。

# 連携の手順

- App Serviceを作成
- Azure App Serviceで、発行プロファイルを準備
  - 認証形式を指定
  - 発行
- GitHub Actionsを作成
  - Actionsのシークレットを指定
  - テンプレートを利用
  - AppService名を指定

## コツ

- App Service側でのログの見方
- TSを利用していた → 完全にビルドしてから、nodeで実行
- ポートの指定
  - App Serviceのデフォルトは 8080
  - 変更も可能？
- 起動コマンドの指定
  - デフォルトは npm start
  - 変更も可能
- シークレットを環境変数で指定
