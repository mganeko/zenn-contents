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

初めてなので、Azure Portalから作成します。画面は2022年9月現在のものです。

- Portalで「Application Gateway」を検索
- 「負荷分散 | Application Gateway」のページを開く
- [アプリケーションゲートウェイの作成]（または単に[作成]）ボタンをクリック
- 「基本」タブで内容を指定
  - サブスクリプション（課金対象）を選択
  - リソースグループ ... 先ほど用意したもの（この例では myAGgroup）を選択
  - ゲートウェイ名 ... 作成するApplication Gatewayの名前を指定。（この例では myAppGateway）
  - 地域 ... 作成する地域（リージョン）を指定。（この例では Japan East）
  - レベル ... Standard V2を選択
  - 自動スケール ... 今回は実験なので「いいえ」を選択
  - インスタンス数 ... 今回は実験なので「1」を指定
  - 可用性ゾーン ... 今回は実験なので「なし」を選択
  - HTTP/2 ... どちらでも良い。ここでは「有効」を選択
  - 仮想ネットワークの構成で、「新規作成」をクリック

![新規ゲートウェイ1](/images/azure_new_app_gateway1.png)
![新規ゲートウェイ2](/images/azure_new_app_gateway2.png)

- 「仮想ネットワークの作成」パネルが開く
  - 名前を指定。この例では myVNet を指定。
  - アドレス範囲はそのまま（10.1.0.0/16)
  - デフォルトのサブネット（最初のサブネット）の名前を変更。この例では myAGSubnet
      - アドレス範囲はそのまま（10.1.0.0/24）
  - 2つ目のサブネットを指定
    - この例では名前は myBackendSubnet
    - アドレス範囲は 10.1.1.0/24
  - [OK]ボタンをクリック

![新規VNet](/images/azure_new_vnet_pannel.png)


- 「アプリケーション ゲートウェイの作成」画面にもどる
  - [次：フロントエンドの数]ボタンをクリック
- 「フロントエンドの数」タブが表示される
  - フロンドエンドIPの種類 ... パブリックを選択
  - パブリックIPアドレス ... 「新規追加」をクリック
    - 名前を指定（例えば myAGPublicIPAddress ）
    - [OK] ボタンをクリック
  - 「フロントエンドの数」タブに戻ったら、[次:バックエンド]ボタンをクリック

![フロントエンド](/images/azure_new_app_gateway_frontend.png)

- 「バックエンド」タブが表示される
  - 「バックエンド プールの追加」をクリック
  - 「バックエンド プールの追加」パネルが表示される
    - 名前を指定（例えば myBackendPool）
    - 「ターゲットを持たないバックエンド プールを追加します」で「はい」を選択
    - [追加]ボタンをクリック
  - 「バックエンド」タブに戻る
    - [次:構成]ボタンをクリック

![バックエンド](/images/azure_add_backend_pannel.png)


- 「構成」タブが表示される
  - 真ん中のルーディング規則の「ルーティング規則の追加」をクリック
  - 「ルーティング規則の追加」パネルが表示される
    - ルール名を指定。この例では myHttpRule
    - 優先度を指定。例えば 300
    - 「リスナー」タブでリスナーを指定
      - リスナー名。例えば myHttpListener
      - フロントエンドIP ... パブリックを選択
      - プロトコル ... HTTPを指定
      - ポート ... 80を入力
      - 追加指定 ... 変更なし（リスナーの種類:BASIC、エラーページのURL:いいえ）
   - 「ルーティング規則の追加」パネルに戻る

![リスナー](/images/azure_appgateway_routing_listener.png)

- 「構成」タブの中
  - 「ルーティング規則の追加」パネルに戻った後
    - 「バックエンドターゲット」タブを選択
      - ターゲットの種類 ... 「バックエンドプール」を選択
      - バックエンドターゲット ... 作成済みの「myBackendPool」を指定
      - バックエンド設定 ... 「新規追加」をクリックして、あたらしく作成
    - 「バックエンドの設定パネル」が開く

![バックエンドターゲット](/images/azure_appgateway_routing_backend_target.png)

- 「バックエンドの設定パネルが開く」が表示された後
  - バックエンド設定名 ... 例えば myHttpSetting
  - バックエンドプロトコル ... HTTPを選択
  - バックエンドポート ... 80
  - 追加設定、ホスト名等 ... そのまま
  - [追加ボタン]をクリック、元の画面に戻る

![リスナー](/images/azure_appgateway_routing_add_backend.png)

- 「ルーティング規則の追加」パネルに戻った後
  - [追加ボタン]をクリック、「構成」タブに戻る
-「構成」タブに戻った後
  - [次：タグ]ボタンをクリック
- 「タグ」タブが表示される
  - 追加指定なし
  - [次：確認および作成]ボタンをクリック
- 「確認および作成」タブが表示される
  - 内容を確認
  - [作成]ボタンをクリック
- 数分後に、Application Gatwayが作成、デプロイされる








  azure_add_backend_pannel


  


