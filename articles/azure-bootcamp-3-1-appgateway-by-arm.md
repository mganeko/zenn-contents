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

### Application Gatewayの構築

まず「Azure Bootcamp 3 - Application Gatewayを使ったVMの簡易Blue-Greenデプロイ](azure-bootcamp-3-application-gateway)」の「[Application Gateway の作成](https://zenn.dev/mganeko/articles/azure-bootcamp-3-application-gateway#application-gateway-の作成)」に従って、Potal画面からApplication Gatewayを構築します。すでに構築済みのものがある場合は、それを利用します。

### ARMテンプレートのエクスポート

- Potalの画面で対象となるApplication Gatewayの内容を表示
- 左のメニューの「テンプレートのエクスポート」をクリック
- [ダウンロード]ボタンをクリック
- zip圧縮されたファイルがダウンロードされる。解凍すると中身は次の2つのファイル
  - template.json ... リソースの定義ファイル
  - parameters.json ... 一部可変なパラメータを指定するファイル

![テンプレートのダウンロード](/images/azure_appgateway_export_template.png)

テンプレートの次のようなJSONファイルです。

```json:template.json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "applicationGateways_myAppGateway_name": {
            "defaultValue": "myAppGateway",
            "type": "String"
        },
        "virtualNetworks_myVNet_externalid": {
            ... 略 ...
            "type": "String"
        },
        "publicIPAddresses_myAGPublicIPAddress_externalid": {
            ... 略 ...
            "type": "String"
        }
    },
    "variables": {},
    "resources": [
        ... 略 ...
    ]
}
```

###  ARMテンプレートの編集

前回の記事ですでに構築済みのApplication Gatewayを使ってARMテンプレートを出力した場合は、バックエンドにVMが追加された状態になっています。テンプレートではバックエンドに何もない状態を作りたいので、その情報を手動で編集します。（Portalから新規に作ったApplication Gatewayからテンプレートを出力した場合には空になっているはずなので、編集は不要です）

resources - backendAddressPools - properties - backendAddresses の配列の中身を削除し、からの配列にします。


```json:before
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion":
    ... 略 ...
    "resources": [
      {
        ... 略 ...
        "backendAddressPools": [
          {
            "name": "appGatewayBackendPool",
            "properties": {
              "backendAddresses": [
                {
                  "ipAddress": "10.1.1.xxx"
                }
              ]
            }
          }
        ],
        ... 略 ...
      }
    ]
}
```

```json:after
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion":
    ... 略 ...
    "resources": [
      {
        ... 略 ...
        "backendAddressPools": [
          {
            "name": "appGatewayBackendPool",
            "properties": {
              "backendAddresses": []
            }
          }
        ],
        ... 略 ...
      }
    ]
```


###  ARMテンプレートのアップロード

準備したARMテンプレートをCloud Shellで利用できるようにアップロードしておきます。

- PotalでCloud Shellを起動
- [アップロード]ボタンをクリック

![アップロード](/images/azure_cloudshell_upload.png)

ホームディレクトリにアップロードされるので、適切なディレクトリ（フォルダ）に移動、必要に応じてファイル名を変更してください。

## ARMテンプレートを利用したApplication Gatewayの構築

### 既存のApplication Gatewayを削除

まず、テンプレートを出力する際に使ったApplication Gatewayがあるはずなので、Potalから削除しておきます。

### テンプレートを使った構築

テンプレートをアップロード後、Cloud Shell上でazコマンドを使って構築します。この例では次の値を想定しています。

- テンプレートファイル名 ... arm/template.json
- リソースグループ名 ... myAGgroup

```shellsession
az deployment group create --resource-group myAGgroup --template-file arm/template.json 
```

数分経つと、Application Gatwayが構築されます。Potal画面で内容を確認してください。Application Gatewayが構築できたら、前回（[Azure Bootcamp 3 - Application Gatewayを使ったVMの簡易Blue-Greenデプロイ](azure-bootcamp-3-application-gateway#blue-greenデプロイのスクリプト化)）のようにサーバーをBlue-Greenデプロイすることができます。


# まとめ

Application Gatewayのように複雑な設定を持つリソースは、毎回手動で構築するのは手間がかかります。ARMテンプレートを用意することで、手軽に再構築することができます。

## シリーズの記事一覧

- 0. [このシリーズについて](azure-bootcamp-0-about)
- 1. [Azure Portalを使って、ブラウザからVMを起動する](azure-bootcamp-1-vm-by-portal)
- 2. [CLIを使って、コマンドでVMを起動する](azure-bootcamp-2-vm-by-cli)
- 3. [Application Gatewayを使ったVMの簡易Blue-Greenデプロイ](azure-bootcamp-3-application-gateway)
- 3.1. [Azure Bootcamp 3.1 - ARMテンプレートを使ったApplication Gatewayのデプロイ](azure-bootcamp-3-1-appgateway-by-arm)




