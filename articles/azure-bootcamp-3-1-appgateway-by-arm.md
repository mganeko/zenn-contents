---
title: "Azure Bootcamp 3.1 - ARMテンプレートを使ったApplication Gatewayのデプロイ" # 記事のタイトル
emoji: "💻" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["azure"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

前回の記事「[Azure Bootcamp 3 - Application Gatewayを使ったVMの簡易Blue-Greenデプロイ](azure-bootcamp-3-application-gateway)」では、Azure Portalの画面からApplication Gatewayを構築しました。これから何度も繰り返し構築と削除を繰り返すことを考えると、毎回Portalの画面から操作するのは手間がかかりすぎます。そこで自動化する方法を2種類試してみます。

# Azure CLIを使ったApplication Gatewayの構築

CLIのazコマンドからも、Application Gatewayを構築することができます。

```shellsession
az network application-gateway create \
  --name myAppGateway \
  --location japaneast \
  --resource-group myAGgroup \
  --capacity 1 \
  --sku Standard_v2 \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --public-ip-address myAGPublicIPAddress \
  --vnet-name myVNet \
  --subnet myAGSubnet \
  --priority 300
```

ここで引数は次の通りです。

- name ... Application Gatewayの名前。この例では myAppGateway
- location ... 作成するリージョン（地域）
- resource-group ... Application Gatewayを配置するリソースグループ。この例では myAGgroup （作成済み）
- capacity ... インスタンスの数
- sku ... SKUの種類
- frontend-port ... リスナーが通信を待ち受ける、フロントエンドのポート
- http-settings-protocol ... リスナーが受け付けるプロトコル
- public-ip-address ... フロントエンドのIPアドレス。この例では myAGPublicIPAddress （作成済み）
- vnet-name ... Application Gatewayを作成する仮想ネットワーク(VNet)。この例では myVNet（作成済み）
- subnet ... Application Gatewayを配置するサブネット。この例では myAGSubnet（作成済み）
- priority ... 作成されるルーティングの優先順位

一方、Potralの画面で指定した項目の一部は引数で指定する方法が見つかりませんでした。

- リスナー名 ... デフォルトの名前になる
- バックエンドプール名 ... デフォルトの名前になる
- バックエンドの通信ポート  ... デフォルトのポート(80)になる

そのため、azコマンドでは前回Portal画面で指定した内容を完全に再現することはできません。


# ARMテンプレートを使ったApplication Gatewayのデプロイ

## Azureのリソース構築の方法

AzureではApplication GatewayやVMといった様々なリソースの構築を自動化するために、次の方法が利用できます。

- Azure Resource Manager テンプレート (ARM テンプレート)
  - リソースの定義情報が記述されたJSONファイル
  - 公式ページ ... [ARM テンプレートとは](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/templates/overview) 
- Bicep
  - 宣言型の構文を使用して Azure リソースをデプロイするドメイン固有言語 (DSL) 
  - ARMテンプレートよりも簡潔で読みやすい
  - 公式ページ ... [Bicep とは](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/overview?tabs=bicep) 

今回は前者のARMテンプレートを使って、Application Gatewayのデプロイを自動化します。

## ARMテンプレートの準備

ARMテンプレートは複雑なため、1から手書きするのは現実的ではありません。代わりにPortal画面を使って、すでに作成済みのリソースから出力（エクスポート）します。


