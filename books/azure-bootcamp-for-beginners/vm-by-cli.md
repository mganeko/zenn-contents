---
title: "Azure CLIを使って、コマンドでVMを起動する" # 記事のタイトル
published: false # 公開設定（falseにすると下書き）
---

# CLIを使ってみよう

この章では、AzureのCLI（コマンドラインインターフェイス）を使って、VMの起動とWebサーバーのセットアップを行います。（コマンドの使い方は2022年8月時点のものです）

コマンドラインから各種操作を行えるようになることが、さまざまな自動化の入り口になります。

## azコマンド: Auzre の CLI

Azureの子マインドラインツール(CLI)は「az」コマンドです。インストール方法は公式サイトを参照するのが確実です。

- [Azure CLI をインストールする方法](https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli)

CLIは次の環境で利用できます。

- Windows、macOS、および Linux 環境
- Dockerコンテナ
- Azure Cloud Shell ... Azure Potal上で利用できるコンソール機能

今回は一番手軽な「Azure Cloud Shell」を使います。

## Cloud Shellの開始

- [Azure Potarl](https://portal.azure.com/) にサインイン
- ポータル画面の一番上、検索エリアのすぐ右の「Cloud Shell」ボタンをクリック

![新規リソース](/images/azure_cloud_shell_button.png)

- 初めてCloud Shellを使う場合は、「ストレージが必要、作るか？」といった趣旨の確認が出るので、OKして継続
  - cloud-shell-storage-_xxxx_ というリソースグループが作成され
  - その中に専用のディスク領域が準備される
- ブラウザの下部にターミナル領域が表示される
  - 「CBL-Mariner/Linux」が起動される … マイクロソフト開発のLinuxディストリビューション

![新規リソース](/images/azure_cloud_shell.png)

### CLI コマンドの確認

```
az version
```

## CLIでリソースグループを作成

