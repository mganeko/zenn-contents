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

今回は特定ユーザーがログインしていなくても起動したいので、サービス（デーモン）として設定します。

```
# 起動
% sudo brew services start ollama

# 停止
% sudo brew services stop ollama
```

### 設定ファイル

サービス起動するとlaunchd用の設定ファイルができます。サービスを停止すると設定ファイルは削除されます。

- /Library/LaunchDaemons/homebrew.mxcl.ollama.plist

この設定ファイルの元になるものは、homebrew側のディレクトリにあります。設定を変更する場合は、元ファイルの方を編集する必要があります。

- /opt/homebrew/Cellar/ollama/_バージョン番号_/homebrew.mxcl.ollama.plist

## ログの確認

今回サービス（デーモン）として指定した後にpsコマンドで確認したところ、実際にはプロセスが存在しませんでした。起動直後に何らかの問題が発生して以上終了している可能性があります。

状況は次のログファイルで確認することができました。

- /opt/homebrew/var/log/ollama.log

```
panic: $HOME is not defined
```

どうやら$HOME環境変数が必要のようです。

## 設定ファイルの編集

サービスの設定ファイルは停止時に削除されてしまうため、homebrew側のディレクトリにあある元になるファイルを編集する必要があります。

- /opt/homebrew/Cellar/ollama/_バージョン番号_/homebrew.mxcl.ollama.plist

今回は次の2つを環境変数(EnvironmentVariables)として指定します。

- 上記ログに出てきた $HOME
- 今回はプロキシ内で動かしているため、モデルダウンロード用にプロキシを指定

```
... 省略 ...
<plist version="1.0">
<dict>
  <key>EnvironmentVariables</key>
    <dict>
      <key>HOME</key>
      <string>/Users/インストールしたユーザー/</string>
      <key>HTTPS_PROXY</key>
      <string>http://proxyサーバー:ポート番号</string>
    </dict>
  ... 省略 ...
```

## 再起動

一旦サービスを停止し、再度起動したところ、正常にサービスのプロセスが立ち上がりました。

## ollamaバージョンアップ時の注意

homebrewを使ってollamaをバージョアップ(upgrade)すると、元になる設定ファイルのディレクトリが変わり、新たに設定ファイルが作られます。

今のところ手動で新しい設定ファイルを再度編集する必要があります。


# nginxによるリバースプロキシの設定


