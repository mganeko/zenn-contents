---
title: "Application Gatewayを使って、VMを簡易Blue-Greenデプロイする" # 記事のタイトル
published: false # 公開設定（falseにすると下書き）
---

# Appllication Gatewayを使った、簡易Blue-Greenデプロイ

## Appllication Gatewayとは

Application GatewayはAzureが提供するロードバランサーサービスの1つです。Azureには複数のロードバランサーがあります。

- Azure Load Balancer
  - https://docs.microsoft.com/ja-jp/azure/load-balancer/load-balancer-overview
  - あらゆる種類の通信の負荷分散が可能(TCP, UDP)
  - レイヤー4で動作。ポート番号とプロトコル単位(TCP, UPD)で負荷分散ルールが設定可能
- Azure Application Gateway
  - https://docs.microsoft.com/ja-jp/azure/application-gateway/overview
  - HTTP/HTTPSの負荷分散が可能
  - レイヤー7で動作
  - HTTPS ←→ HTTP 変換（TLS終端）が可能
- Azure Traffic Manager
  - https://docs.microsoft.com/ja-jp/azure/traffic-manager/traffic-manager-overview
  - DNSレベルで複数のIPアドレスに負荷分散を行う
  - リージョンを跨った負荷分散が可能
- Azure Front Door
  - https://docs.microsoft.com/ja-jp/azure/frontdoor/front-door-overview
  - HTTP/HTTPSの負荷分散が可能
  - リージョンを跨った負荷分散が可能
  - CDNやWAFの機能を統合

※公式サイトの解説: 負荷分散のオプション
- https://docs.microsoft.com/ja-jp/azure/architecture/guide/technology-choices/load-balancing-overview

今回は HTTPS ←→ HTTP 変換（TLS終端）も意識して、Application Gatway を利用します。

## リソースグループの作成

まずはリソースをまとめて管理するリソースグループを作成します。Azure Potralからでも、CLIからでもどちらでもOKです。ここでは Cloud Shell上からCLI(azコマンド)で作成しておきます。（名前は例えば myAGgroup とします）

```shellsession
az group create --name myAGgroup --location japaneast
```

## Application Gateway の作成　

初めてなので、Azure Portalから作成します。

- Portalで「Application Gateway」を検索
- 「負荷分散 | Application Gateway」のページを開く
- [アプリケーションゲートウェイの作成]ボタンをクリック
- 「基本」タブで内容を指定
  - サブスクリプション（課金対象）を選択
  - リソースグループ ... 先ほど用意したもの（この例では myAGgroup）を選択
  - ゲートウェイ名 ... 作成するApplication Gatewayの名前を指定。（この例では myAppGateway）
  - 地域 ... 作成する地域（リージョン）を指定。（この例では Japan East）
  - レベル ... Standard V2を選択
  - 自動スケール ... 今回は実験なので「いいえ」を選択
  - インスタンス数 ... 今回は実験なので「1」を指定

![新規ゲートウェイ1](/images/azure_new_app_gateway1.png)

- 「基本」タブの続き

