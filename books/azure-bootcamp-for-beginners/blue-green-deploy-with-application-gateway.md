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
  - レイヤー4で動作。ポート番号とプロトコル単位(TCP, UPD0で負荷分散ルールが設定可能
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


