---
title: "Ollamaのサーバーを、Macでサービスとして利用する場合の注意点" # 記事のタイトル
emoji: "🦙" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["macOS", "LLM", "ollama"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

この記事は非公式の[Infocom Advent Calendar 2024](https://qiita.com/advent-calendar/2024/infocom)のxx日目の記事です。

# やりたいこと

- ローカルLLM実行ツールの[ollama](https://ollama.com)を、誰もログインしていない状態で動かしたい
  - いわゆるServiceやdaemonの状態
- nginxでリバースプロキシをたて、他のマシンから接続できるようにしたい

# Ollamaをサービスとして起動する

## Ollamaのインストール

今回はインストーラーではなく、homebrewでインストール

```
% brew install ollama
```

インストール先
- /opt/homebrew/bin/ollama


## サービスとして起動

```
# 起動
% sudo brew services start ollama

# 停止
% sudo brew services stop ollama
```

/Library/LaunchDaemons/homebrew.mxcl.ollama.plist

~/Library/LaunchAgents/homebrew.mxcl.ollama.plist


## ログの確認


/opt/homebrew/var/log/ollama.log

```
panic: $HOME is not defined
```

どうやら環境変数が必要

/opt/homebrew/Cellar/ollama/_バージョン番号_/homebrew.mxcl.ollama.plist

```
  ... 省略 ...
  <key>EnvironmentVariables</key>
    <dict>
      <key>HOME</key>
      <string>/Users/インストールしたユーザー/</string>      <key>HTTPS_PROXY</key>
      <string>http://proxyサーバー:ポート番号</string>
    </dict>
  ... 省略 ...
```


# nginxによるリバースプロキシの設定


