---
title: "Azure CLIを使って、コマンドでVMを起動する" # 記事のタイトル
published: false # 公開設定（falseにすると下書き）
---

# CLIを使ってみよう

この章では、AzureのCLI（コマンドラインインターフェイス）を使って、VMの起動とWebサーバーのセットアップを行います。（コマンドの使い方は2022年8月時点のものです）

コマンドラインから各種操作を行うことが、さまざまな自動化の入り口になります。

## azコマンド: Auzre の CLI

Azureのコマンドラインインターフェイス(CLI)は「az」コマンドです。インストール方法は公式サイトを参照するのが確実です。

- [Azure CLI をインストールする方法](https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli)

CLIは次の環境で利用できます。

- Windows、macOS、および Linux 環境
- Dockerコンテナ
- Azure Cloud Shell ... Azure Potal上で利用できるコンソール機能

今回は一番手軽な「Azure Cloud Shell」を使います。（CLIのインストール不要）

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

Cloud Shell上で、次のコマンドを実行し、azコマンドが動くことを確認します。


```
$ az version
{
  "azure-cli": "2.39.0",
  "azure-cli-core": "2.39.0",
  "azure-cli-telemetry": "1.0.6",
  "extensions": {
    "ai-examples": "0.2.5",
    "azure-cli-ml": "1.41.0",
    "ssh": "1.1.2"
  }
}
```

- ※ここで「\$」で始まる行が入力するコマンド
  - ただし、先頭の\$ はプロンプトなので入力しない
- ※先頭に「\$」の無い行が出力結果

azコマンドの詳細は、公式リファレンスを参照してください

- https://docs.microsoft.com/ja-jp/cli/azure/reference-index?view=azure-cli-latest


## CLIでリソースグループを作成

Cloud Shell上で、CLI(azコマンド)を使って、リソースグループを作成します。この例では作成するリソースグループ名を「myCLIgroup」とします。

```
$ az group create --name myCLIgroup --location japaneast
{
  "id": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/myCLIgroup",
  "location": "japaneast",
  "managedBy": null,
  "name": "myCLIgroup",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```

ここでオプション指定は次の通りです。

- --name リソーグループ名を指定
- --location 作成する地域を指定
