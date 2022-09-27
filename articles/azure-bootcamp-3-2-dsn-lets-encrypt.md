---
title: "Azure Bootcamp 3.2 - Application GatewayのDNSの指定とHTTPS化" # 記事のタイトル
emoji: "🌩️" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["azure"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

以前の記事「[Azure Bootcamp 3 - Application Gatewayを使ったVMの簡易Blue-Greenデプロイ](azure-bootcamp-3-application-gateway)」で構築したApplication GatewayにDNS名の指定を行い、HTTPS化してみましょう。SSL(TLS)の証明書にはLets's Encrpytを利用します。

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

```textile:実行結果の例
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

## Application GatewayによるTLSの終端

Application Gatewayはレイヤー7で動作するので、次の図のようにTLSの証明書を使ってHTTPS→HTTPの変換（SSLの終端）を行うことができます。バックエンドのサーバーが複数ある場合に個別に証明書を設定する必要がなくなり、便利です。

![新規ゲートウェイ1](/images/azure_appgateway_https_terminate.png)

## Let's Encryptとは

Webの安全性を向上させるため、常時SSL（Always On SSL）という取り組みが進んでいます。その一環として無料でSSL証明書を提供するサービスが出てきており、Internet Security Research Groupが運営するLet's Encryptもその一つです。

- [Let's Encpryt - はじめる](https://letsencrypt.org/ja/getting-started/)

SSL証明書はIPアドレスではなくドメインを使ったサーバー名に対して発行されます。そのため、あらかじめDNS名を指定してドメインを含む名前（FQDN）でアクセスできるようにしました。

## Certbotの利用

Let's EncrpytでSSL証明書を発行するために、Linux VM上で[certbot](https://certbot.eff.org) というツールを利用します。VMはこれまでのは別の、第3のサブネットに配置します。

## サブネットの作成

certbot用に新たなサブネットを作成します。PotalのCloud Shell上でazコマンドを用いて作成します。

```shellsession
RGNAME="myAGgroup"
VNET="myVNet"
SUBNET="myCertbotSubnet"
SUBNETRANGE="10.1.2.0/24"

az network vnet subnet create \
  --name $SUBNET \
  --resource-group $RGNAME \
  --vnet-name $VNET   \
  --address-prefix $SUBNETRANGE
```

この例では、次を想定しています。

- 仮想ネットワーク(VNet) ... myVnet
- サブネット名 ... myCertbotSubnet
- サブネットのアドレス範囲 ... 10.1.2.0/24"

## VMの作成

次に用意したサブネットにVMを作ります。Cloud Shell上で次のコマンドを実行します。

```
RGNAME="myAGgroup"
VNET="myVNet"
SUBNET="myCertbotSubnet"
SERVERNAME="myVMcertbot"

az vm create \
  --resource-group $RGNAME \
  --name $SERVERNAME \
  --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest \
  --size Standard_B1ls \
  --public-ip-sku Standard \
  --subnet $SUBNET \
  --vnet-name $VNET \
  --storage-sku StandardSSD_LRS \
  --nic-delete-option Delete \
  --os-disk-delete-option Delete \
  --admin-username azureuser \
  --generate-ssh-keys
```

作成に成功したら、次のようなメッセージが返ってきます。

```textile
{
  "fqdns": "",
  "id": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx/resourceGroups/myAGgroup/providers/Microsoft.Compute/virtualMachines/myVMcertbot",
  "location": "japaneast",
  "macAddress": "xx-xx-xx-xx-xx-xx",
  "powerState": "VM running",
  "privateIpAddress": "10.1.2.x",
  "publicIpAddress": "xxx.xxx.xxx.xxx",
  "resourceGroup": "myAGgroup",
  "zones": ""
}
```

作成したVMには新たにパブリックIPアドレス(publicIpAddress)が割り振られているので、それを記録しておいてください。
また次のようにコマンドで取得し、環境変数に設定しておくと便利です。

```shellsession
VMIP=$(az vm show --show-details --resource-group $RGNAME --name $SERVERNAME --query publicIps -o tsv)
echo $VMIP
```


## VMのセットアップ

### VMへの接続

Cloud Shell上から、sshを用いて接続します。初回は接続を確認されるので、yesと答えてください

```shellsession:CloudShell上
ssh azureuser@$VMIP
```

### Nginxのインストール

VMに接続できたら、パッケージのアップデートと、Webサーバー(Nginx)のインストールを行います。

```shellsession:VM上
sudo apt update && sudo apt upgrade -y && sudo apt-get install -y nginx
```

インストール終了後、次のコマンドでHTMLが返って来ればNginxのインストールはは成功です。

```shellsession:VM上
curl http://localhost/
```

### Certbotのインストール

Certbotの公式説明([certbot instructions](https://certbot.eff.org/instructions?ws=nginx&os=ubuntufocal))に従い、次のコマンドでインストールを行います。

```shellsession:VM上
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

次にインストールしたcertbotコマンドを利用して証明書を発行するのですが、その前に Application Gatewayに指定したDNS名(FQDN)を使って、このVMに接続できるように準備が必要です。

sshをexitで抜けて、Cloud Shellに戻ってから、続行してください。


## Application Gatewayの複数バックエンドプール指定

Application Gatewayには複数のバックエンドプールを指定できます。Cloud Shell上から、azコマンドでバックエンドプール（address-pool)を追加します。

```shellsession:CloudShell上
RGNAME="myAGgroup"
APPGATEWAY="myAppGateway"
BACKENDPOOL="myCertbotPool"

az network application-gateway address-pool create \
--resource-group $RGNAME \
--gateway-name $APPGATEWAY \
--name $BACKENDPOOL
```

作成したバックエンドプールの一覧は、次のコマンドで取得できます。

```shellsession:CloudShell上
az network application-gateway address-pool list --gateway-name $APPGATEWAY \
  --resource-group $RGNAME --query "[].{name: name}" -o tsvmyBackendPool
```

## Potalからバックエンドプールを追加

Azure Portal上で、作成済みのApplication Gatewayを表示します。

- 左のメニューから「バックエンドプール」をクリック
- [+追加]ボタンをクリック

![バックエンドプール](/images/azure_appgateway_backendpool.png)


- 「バックエンドプール」パネルが表示される
  - 名前を指定 ... 例） myCertbotPool
  - ターゲットの種類で「仮想マシン」を選択
  - ターゲットで、certbot用に作成したVMのネットワークインターフェイス（例：myVMcertbotVMNic）を選択
  - [追加]ボタンをクリック

![バックエンドプールパネル](/images/azure_appgateway_add_backendpool.png)

- Application Gatewayの画面に戻る
- 左のメニューから「バックエンド設定」をクリック
- [+追加]ボタンをクリック
- 「バックエンド設定の追加」パネルが表示される
  - 名前 ... certbotSetting
  - プロトコル ... HTTP
  - ポートは ... 80
  - 他はそのまま
  - [保存]ボタンをクリック

![バックエンド設定](/images/azure_appgateway_backend_certbot_setting.png)


- Application Gatewayの画面に戻る
- 左のメニューから「リスナー」をクリック
- [+リスナーの追加]ボタンをクリック
- 「リスナーの追加」パネルが表示される
  - 名前 ... dummyListener
  - プロントエンドIP ... パブリック
  - プロトコル ... HTTP
  - ポート ... 8080 (80以外のポートを指定)
  - 他はデフォルトのまま
  - [追加]ボタンをクリック

![リスナー追加パネル](/images/azure_appgateway_add_listner_panel.png)


--

- Application Gatewayの画面に戻る
- 左のメニューから「ルール」をクリック
- 今あるルール (myHttpRule) を削除
- [+ルーティング規則]ボタンをクリック




/.well-known/*






VM上で


sudo certbot certonly --nginx
--> emailアドレスを入力

Please read the Terms of Service a
-> y

emailアドレスをシェアするか？
--> n

domain name
--> my-dns-name-2022.japaneast.cloudapp.azure.com


-->
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/my-dns-name-2022.japaneast.cloudapp.azure.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/my-dns-name-2022.japaneast.cloudapp.azure.com/privkey.pem
