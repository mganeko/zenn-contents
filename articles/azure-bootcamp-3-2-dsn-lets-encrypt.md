---
title: "Azure Bootcamp 3.2 - Application GatewayのDNSの指定とHTTPS化" # 記事のタイトル
emoji: "🌩️" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["azure"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

以前の記事「[Azure Bootcamp 3 - Application Gatewayを使ったVMの簡易Blue-Greenデプロイ](azure-bootcamp-3-application-gateway)」で構築したApplication GatewayにDNS名の指定を行い、HTTPS化してみましょう。TLSの証明書にはLets's Encrpytを利用します。

## Aplication Gatewayを再構築する場合

もしApplication Gatewayを削除していたら、いずれかの方法で再度構築してください。

- [Application Gateway の作成](azure-bootcamp-3-application-gateway#application-gateway-の作成)
- [ARMテンプレートを利用したApplication Gatewayの構築](azure-bootcamp-3-1-appgateway-by-arm#armテンプレートを利用したapplication-gatewayの構築)

# DNS名の指定


以前の記事「[dnsの設定](azure-bootcamp-2-vm-by-cli#dnsの設定)」の中で書いたように、パブリックIPアドレスに対してazコマンドを利用してDNS名を指定できます。この例では次の環境、名前を使っています（自分の環境に合わせた名前に置き換えてください）

- リソースグループ名　... myAGgroup
- パブリックIPアドレス名 ... myAGPublicIPAddress
- DNS名 ... 好きな名前（例: my-dns-name-2022 ）
  - ※DNS名はその地域（リージョン）でユニークな名前の必要あり。他のユーザがすでに利用している場合は指定できない

## azコマンドでのDNS指定

Cloud Shell上から次のようにazコマンドを実行します。

```shellsession
RGNAME="myAGgroup"
IPNAME="myAGPublicIPAddress"
DNSNAME="my-dns-name-2022"
az network public-ip update --resource-group $RGNAME -n $IPNAME --dns-name $DNSNAME 
```

## 結果の確認

結果は次のコマンドで確認できます。

```shellsession
az network public-ip list -g $RGNAME --query "[].{ fqdn: dnsSettings.fqdn }"
```

```json:実行結果の例
[
  {
    "fqdn": "my-dns-name-2022.japaneast.cloudapp.azure.com"
  }
]
```

## ブラウザでのアクセス

サーバーがデプロイ済みであれば、ブラウザから次のようにDSN名を使ってアクセスできるはずです。例えば地域（リージョン）が Japan Eastの場合、次のようなURLになります。

- http://_指定したDNS名_.japaneast.cloudapp.azure.com/

Application Gatewayのバックエンドプールにサーバーが何もない場合は、サーバーをデプロイしてからブラウザでアクセスしてください。

- [（簡易）blue-greenデプロイの実行](azure-bootcamp-3-application-gateway#（簡易）blue-greenデプロイの実行)

# Let's Encryptを使ったHTTPS化
