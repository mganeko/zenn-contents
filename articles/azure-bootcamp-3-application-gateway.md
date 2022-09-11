---
title: "Azure Bootcamp 3 - Application Gatewayを使ったVMの簡易Blue-Greenデプロイ" # 記事のタイトル
emoji: "💻" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["azure"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# Appllication Gatewayを使った、簡易Blue-Greenデプロイ

## Appllication Gatewayとは

Application GatewayはAzureが提供するロードバランサーサービスの1つです。Azureには複数のロードバランサーがあります。（※ロードバランサーは、同じIPアドレスへのアクセスを複数のサーバーに負荷分散させる仕組みです）

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

## ネットワーク関連リソースの作成

リソースグループができたら、ネットワーク関連のリソースを作成します。

- 仮想ネットワーク(VNet)
- サブネットワーク （仮想ネットワーク内を、さらに区切るもの）× 2
- パブリックIPアドレス

![新規ゲートウェイ1](/images/azure_vnet_subnet.png)

まとめて作るために、Cloud Shell上でシェルスクリプトを作成します。スクリプトの中ではazコマンドを複数回実行して、必要なリソースを作ります。（VNet名、サブネット名など、適宜変更してください）

```shell:create_network.h
#!/bin/sh
#
# create_network.sh
#
# usege:
#   sh create_network.sh resorucegoupname

# --- check args ---
if [ $# -ne 1 ]; then
  echo "ERROR: Please specify resouce-group-name (1 arg)." 1>&2
  exit 1
fi
RESOUCEGROUP=$1

VNET="myVNet"
VNETRANGE="10.1.0.0/16"
SUBNET1="myAGSubnet"
SUBNET1RANGE="10.1.0.0/24"
SUBNET2="myBackendSubnet"
SUBNET2RANGE="10.1.1.0/24"
PUBLICIPNAME="myAGPublicIPAddress"


# --- create VNet and gateway subnet ---
az network vnet create \
  --name $VNET \
  --resource-group $RESOUCEGROUP \
  --location japaneast \
  --address-prefix $VNETRANGE \
  --subnet-name $SUBNET1 \
  --subnet-prefix $SUBNET1RANGE
echo "-- VNET created --"

# --- create backend subnet ---
az network vnet subnet create \
  --name $SUBNET2 \
  --resource-group $RESOUCEGROUP \
  --vnet-name $VNET   \
  --address-prefix $SUBNET2RANGE
echo "-- backend subnet created --"

# --- create public IP address ---
az network public-ip create \
  --resource-group $RESOUCEGROUP \
  --name $PUBLICIPNAME \
  --allocation-method Static \
  --sku Standard

PUBLICIPADDR=$(az network public-ip list -g myAGgroup --query "[?name == '$PUBLICIPNAME'].{ip: ipAddress}" -o tsv)
echo "-- PublicIP created. address=" $PUBLICIPADDR " --"

exit 0
```

シェルスクリプトが準備できたら、Cloud Shell上から引数にリソースグループ名（この例では myAGgroup ）を渡して実行します。

```shellsession
sh create_network.sh myAGgroup
```

成功するとパブリックIPアドレスが表示されます。あとでブラウザでアクセスするために記録しておきます。


## Application Gateway の作成　

初めてなので、Azure Portalから作成します。画面は2022年9月現在のものです。

- Portalで「Application Gateway」を検索
- 「負荷分散 | Application Gateway」（あるいはアプリケーションゲートウェイ）のページを開く
- [アプリケーションゲートウェイの作成]（または単に[＋作成]）ボタンをクリック
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
  - 仮想ネットワークの構成
    - 仮想ネットワーク ... 作成済みの仮想ネットワーク（この例では myVNet）を選択
    - サブネット ... 作成済みのもの（この例では myAGsubnet）を選択
  - [次：フロントエンドの数]ボタンをクリック

![新規ゲートウェイ1](/images/azure_new_app_gateway.png)

- 「フロントエンドの数」タブが表示される
  - フロンドエンドIPの種類 ... パブリックを選択
  - パブリックIPアドレス ... 作成済みのもの（この例では myAGPublicIPAddress）を選択
  - [次:バックエンド]ボタンをクリック

![フロントエンド](/images/azure_new_app_gateway_front.png)

- 「バックエンド」タブが表示される
  - 「バックエンド プールの追加」をクリック
  - 「バックエンド プールの追加」パネルが表示される
    - 名前を指定（例えば myBackendPool）
    - 「ターゲットを持たないバックエンド プールを追加します」で「はい」を選択
    - [追加]ボタンをクリック
  - 「バックエンド」タブに戻る
    - [次:構成]ボタンをクリック

![バックエンド](/images/azure_add_backend_pannel.png =400x)


- 「構成」タブが表示される
  - 真ん中のルーディング規則の「ルーティング規則の追加」をクリック
  - 「ルーティング規則の追加」パネルが表示される
    - 「ルーティング」タブが選択されている
    - ルール名を指定。この例では myHttpRule
    - 優先度を指定。例えば 300
    - 「リスナー」タブでリスナーを指定
      - リスナー名。例えば myHttpListener
      - フロントエンドIP ... パブリックを選択
      - プロトコル ... HTTPを指定
      - ポート ... 80を入力
      - 追加指定 ... 変更なし（リスナーの種類:BASIC、エラーページのURL:いいえ）

![リスナー](/images/azure_appgateway_routing_listener.png)

- 「構成」タブの中
  - 「ルーティング規則の追加」パネルの中で操作を継続
    - 「バックエンドターゲット」タブを選択
      - ターゲットの種類 ... 「バックエンドプール」を選択
      - バックエンドターゲット ... 作成済みの「myBackendPool」を指定
      - バックエンド設定 ... 「新規追加」をクリックして、あたらしく作成
    - 「バックエンドの設定パネル」が開く

![バックエンドターゲット](/images/azure_appgateway_routing_backend_target2.png)

- 「バックエンドの設定パネルが開く」が表示された後
  - バックエンド設定名 ... 例えば myHttpSetting
  - バックエンドプロトコル ... HTTPを選択
  - バックエンドポート ... 8080
  - 追加設定、ホスト名等 ... そのまま
  - [追加ボタン]をクリック、元の画面に戻る

![リスナー](/images/azure_appgateway_routing_add_backend2.png)

- 「ルーティング規則の追加」パネルに戻った後
  - [追加ボタン]をクリック、「構成」タブに戻る
- 「構成」タブに戻った後
  - [次：タグ]ボタンをクリック
- 「タグ」タブが表示される
  - 追加指定なし
  - [次：確認および作成]ボタンをクリック
- 「確認および作成」タブが表示される
  - 内容を確認
  - [作成]ボタンをクリック
- 数分後に、Application Gatwayがと関連リソースが作成、デプロイされる
  - Appllication Gateway
  - バックエンドプール
  - リスナー
  - ルーティング規則
  - バックエンド設定

Application Gatewayのデプロイが完了すると、関連リソースも含めて次のようなリソースが作成された状態になります。（インターネットからパブリックIPアドレスへの 80/TCP ポートへのHTTPアクセスを受けて、バックエンドプールの 8080/TCP ポートに繋げる）

![関連リソース](/images/azure_application_gatway_resources.png)

バックエンドプールはまだ何もない空っぽの状態なので、パブリックIPアドレスにブラウザでアクセスすると、「502 Bad Gateway」と表示されます。

## VMの切り替え 簡易Blue-Greenデプロイ

### Blue-Greenデプロイとは

Blue-Greenデプロイ（デプロイメント）は、アプリケーションの新バージョンをリリースする際に、できるだけ限りダウンタイムを短くするための方法です。次のような手順を取ります。

- 外部からのアクセスは、ルーター等のゲートウェイを経由する
- 現在稼働中のサーバーを「Blue系」とする
- 新バージョンのサーバーを「Green系」にデプロイする
- 「Green系」は非公開のまな、稼働確認テストを行う
- テストをパスしたら、ゲートウェイ経由の外部からのアクセスを「Green系」に切り替える
- 「Blue系」へのアクセスが全て無くなったら、「Blue系」を切り離し、シャットダウンする

![Blue-Green](/images/blue_green_deployment.png)


### 今回目指すこと

今回はApplication Gatwayを使って、バックエンドのVMの作成、切り替え、削除を Blue-Greenデプロイします。複数回繰り返せるように、必要な処理を実行するシェルスクリプトを準備します。

またテストと外部からのアクセス有無の確認を省略しているため、「簡易」Blue-Greenデプロイと位置付けています。

### VM作成時の初期化処理：cloud-initの利用

多くのクラウドプラットフォームでは、VM作成時に初期化処理を行う [cloud-init](https://cloudinit.readthedocs.io/en/latest/) をサポートしています。もちろんAzureでも利用できます。

- [Azure での仮想マシンに対する cloud-init のサポート](https://docs.microsoft.com/ja-jp/azure/virtual-machines/linux/using-cloud-init)

今回はNode.jsを利用したサーバーを起動します。初期化には cloud-initを使いますが、VM作成時に一部を変更できるように、テンプレートファイルとシェルスクリプトを併用します。

```yaml:cloud-init-template.txt
#cloud-config
package_upgrade: true
packages:
  - nodejs
  - npm
write_files:
  - owner: azureuser:azureuser
    path: /home/azureuser/myapp/index.js
    content: |
      const express = require('express')
      const app = express()
      const os = require('os');
      const port = 8080;
      const helloMessage = 'HELLOMESSAGE';
      app.get('/', function (req, res) {
        res.send('Hello, ' + helloMessage);
      });
      app.listen(port, function () {
        console.log('Hello app listening on port ' + port);
      });
runcmd:
  - cd "/home/azureuser/myapp"
  - npm init
  - npm install express -y
  - nodejs index.js
```

```shell:prepare_cloudinit.sh
#!/bin/sh
#
# prepare_cloudinit.sh
#
# usege:
#   sh prepare_cloudinit.sh message

# --- check args ---
if [ $# -ne 1 ]; then
  echo "ERROR: Please specify Message (1 arg)." 1>&2
  exit 1
fi
MESSAGE=$1

# -- copy template-file to work-file --
cp cloud-init-template.txt cloud-init-work.txt

# -- replate message variable --
sed -i.bak "s/HELLOMESSAGE/$MESSAGE/" cloud-init-work.txt

```


### cloud-initを用いたVM作成

NIC1を使う場合

```
az vm create \
  --resource-group myAGgroup \
  --name myVMblue \
  --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest \
  --size Standard_B1ls \
  --public-ip-sku Standard \
  --storage-sku StandardSSD_LRS \
  --nics myNic1 \
  --nic-delete-option Detach \
  --os-disk-delete-option Delete \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data cloud-init-work.txt
```

NIC2を使う場合

```
az vm create \
  --resource-group myAGgroup \
  --name myVMgreen \
  --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest \
  --size Standard_B1ls \
  --public-ip-sku Standard \
  --storage-sku StandardSSD_LRS \
  --nics myNic2 \
  --nic-delete-option Detach \
  --os-disk-delete-option Delete \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data cloud-init-work.txt
```

VMとNICを作成、public-ip なし、サブネット指定

```
SERVERNAME=myVMyellow

az vm create \
  --resource-group myAGgroup \
  --name $SERVERNAME \
  --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest \
  --size Standard_B1ls \
  --public-ip-sku Standard \
  --public-ip-address "" \
  --subnet myBackendSubnet \
  --vnet-name myVNet \
  --nsg "" \
  --storage-sku StandardSSD_LRS \
  --nic-delete-option Delete \
  --os-disk-delete-option Delete \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data cloud-init-work.txt
```

プライベートIPアドレス取得

```
PRIVATEID=$(az vm show --show-details --resource-group myAGgroup --name $SERVERNAME --query privateIps -o tsv)
echo $PRIVATEID

```

動作確認

```shellsession
az vm run-command invoke \
  --resource-group myAGgroup \
  --name $SERVERNAME \
  --command-id RunShellScript \
  --scripts "ps -ef | grep nodejs | grep index.js"
```

```
az vm run-command invoke \
  --resource-group myAGgroup \
  --name myVMblue \
  --command-id RunShellScript \
  --scripts "curl http://localhost:8080/"
```

結果

```
{
  "value": [
    {
      "code": "ProvisioningState/succeeded",
      "displayStatus": "Provisioning succeeded",
      "level": "Info",
      "message": "Enable succeeded: \n[stdout]\nHello, HELLOMESSAGEVAR\n[stderr]\n  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current\n                                 Dload  Upload   Total   Spent    Left  Speed\n\r  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0\r100    22  100    22    0     0    157      0 --:--:-- --:--:-- --:--:--   157\n",
      "time": null
    }
  ]
}
```

バックエンドに追加

```
az network application-gateway address-pool update -g myAGgroup \
  --gateway-name myAppGateway -n myBackendPool \
  --add backendAddresses ipAddress=$PRIVATEID
```

一覧

```
az network application-gateway address-pool show -g myAGgroup --gateway-name myAppGateway -n myBackendPool
```

削除

```
az network application-gateway address-pool update -g myAGgroup \
--gateway-name myAppGateway -n myBackendPool \
--remove backendAddresses 0
```


アクセス確認

```
curl http://パブリックIPアドレス/
```

