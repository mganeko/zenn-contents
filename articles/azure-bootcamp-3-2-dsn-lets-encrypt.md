---
title: "Azure Self-Study 3.2 - Application GatewayのDNSの指定とHTTPS化" # 記事のタイトル
emoji: "🌩️" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["azure"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---

# はじめに

以前の記事「[Azure Self-Study 3 - Application Gatewayを使ったVMの簡易Blue-Greenデプロイ](azure-bootcamp-3-application-gateway)」で構築したApplication GatewayにDNS名の指定を行い、HTTPS化してみましょう。SSL(TLS)の証明書にはLets's Encrpytを利用します。

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

Let's EncrpytでSSL証明書を発行するために、Linux VM上で[certbot](https://certbot.eff.org) というツールを利用します。VMはこれまでとは別の、第3のサブネットに配置します。

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

次にインストールしたcertbotコマンドを利用して証明書を発行します。発行する際には次のURLでcertbotが生成する特殊なファイルにアクセスできる必要があります。

- http://_FQDN名_/.well-known/acme-challenge/_xxxxxxxxxxxxxxxx_

それを実現するために、Application Gateway経由でこのVM上のWebサーバー(Nginx)に接続できるように準備が必要です。
（sshをexitで抜けて Cloud Shellに戻ってから、続行してください。）

## Application Gatewayへのバックエンドプールの追加

Application Gatewayにバックエンドプールを追加し、certbot用に作ったVMを配置します。


Azure Portal上で、作成済みのApplication Gatewayを表示します。

- 左のメニューから「バックエンドプール」をクリック
- [+追加]ボタンをクリック

![バックエンドプール](/images/azure_appgateway_backendpool.png =500x)


- 「バックエンドプール」パネルが表示される
  - 名前を指定 ... 例） myCertbotPool
  - ターゲットの種類で「仮想マシン」を選択
  - ターゲットで、certbot用に作成したVMのネットワークインターフェイス（例：myVMcertbotVMNic）を選択
  - [追加]ボタンをクリック

![バックエンドプールパネル](/images/azure_appgateway_add_backendpool.png =500x)

- Application Gatewayの画面に戻る
- 左のメニューから「バックエンド設定」をクリック
- [+追加]ボタンをクリック
- 「バックエンド設定の追加」パネルが表示される
  - 名前 ... certbotSetting
  - プロトコル ... HTTP
  - ポートは ... 80
  - 他はそのまま
  - [保存]ボタンをクリック

![バックエンド設定](/images/azure_appgateway_backend_certbot_setting.png =500x)


## Application Gatewayによるパス別のルーティング

### 実現したい姿

次のように、パス別に異なるバックエンドに分岐させることを目指します。

- http://_FQDN名_/.well-known/* ... certbot用に作ったVM（Nginx）
- それ以外の http://_FQDN名_/* ... 元々あるバックエンドプール（Node.jsを使ったサーバー）

図にすると次のような形です。

![パス別ルーティング](/images/azure_appgateway_routing_goal.png)

### 経由する姿

ところがAppplication Gatewayの設定変更には下記の制約があり、ストレートに上記の形を実現できません。

- すでに作ってあるルーティング規則（BASICルーティング）に、パスのルールを追加することはできない
  - パスのルールを追加するには、新たにルーティング規則を作ってそこに追加する
- ルーティング規則を全て削除することはできない
  - 最低1つはルーティング規則が存在している必要あり
  - 新しいルーティング規則を追加後、古いルーティング規則を削除する
- リスナーは、複数のルールで使うことはできない
  - 新しいルーティング規則用に、新しいリスナーを用意する必要がある
  - 古いリーティング規則の削除後は、元々あったリスナーを再利用できる

従って一旦次の形を作ります。

![暫定ルーティング](/images/azure_appgateway_routing_step1.png)


## Application Gatewayへの新しいルーティング規則の追加

### ダミーのリスナーを追加

Azure Portal上で、作成済みのApplication Gatewayを表示します。

![リスナー](/images/azure_appgateway_add_listener.png =500x)

- 左のメニューから「リスナー」をクリック
- [+リスナーの追加]ボタンをクリック
- 「リスナーの追加」パネルが表示される
  - 名前 ... dummyListener
  - プロントエンドIP ... パブリック
  - プロトコル ... HTTP
  - ポート ... 8080 (80以外のポートを指定)
  - 他はデフォルトのまま
  - [追加]ボタンをクリック
- Application Gatewayの画面に戻る

![リスナー追加パネル](/images/azure_appgateway_add_listner_panel.png =500x)

### ルーティング規則を追加

引き続きAzure Portal上でApplication Gatewayの設定を行います。

![ルール](/images/azure_appgateway_rule.png =500x)


- 左のメニューから「ルール」をクリック
- [+ルーティング規則]ボタンをクリック
- 「ルーティング規則の追加」パネルが表示される
  - ルール名 ... myCertbotRule
  - 優先度 ... 100
  - 「リスナー」タブをクリック
    -　リスナー ... 先ほど作った「dummyListener」を選択

![ルール](/images/azure_appgateway_add_rule_panel1.png =500x)

- 「ルーティング規則の追加」パネルでの操作を継続
  - 「バックエンドターゲット」タブをクリック
    - ターゲットの種類 ... 「バックエンドプール」を選択
    - バックエンドターゲット ... 元々作ってあった「myBackendPool」を指定
    - バックエンド設定 ... 元々作ってあった「myHttpSetting」を指定

![ルール](/images/azure_appgateway_add_rule_panel2_backend.png =500x)

- 「ルーティング規則の追加」パネルでの操作を継続
  - 「バックエンドターゲット」タブでの操作を継続
    - パスベースの規則
      - 「パス ベースの規則を作成するには複数のターゲットを追加します」をクリック
      - パスの指定画面が表示される
        - パス ... /.well-known/*
        - ターゲット名 ... certbot
        - バックエンド設定 ... 今回作った「certbotSetting」を指定
        - バックエンドターゲット ... 今回作った「myCertbotPool」を指定
        - [追加]ボタンをクリック
      - パスベースの規則の表示に戻る
    - [追加]ボタンをクリック
  - 「ルーティング規則」の一覧に戻る

![パス指定](/images/azure_appgateway_add_rule_panel3_addpath.png =500x)

ここまでの設定が終わるとブラウザで次のURLにアクセスできるようになっています。

- http://_FQDN名_:8080/ あるいは
- http://_指定したDNS名_.japaneast.cloudapp.azure.com:8080/

ルーティングの状態は次のようになっています。

![暫定ルーティング](/images/azure_appgateway_routing_step1.png)


### 元のルーティング規則を削除

Azure Portal上でApplication Gatewayの設定を続けます。

- 左のメニューから「ルール」をクリック
  - ルールの一覧から、元々あった「myHttpRule」の右端の「…」のメニューから、「削除」をクリック
  - 元の「myHttpRule」が削除され、元々あった「myHttpListner」が使えるようになる

![ルールの削除](/images/azure_appgateway_rule_list_delete.png =500x)


### 新しいルーティング規則を変更

もう少しAzure Portal上でApplication Gatewayの設定を続けます。

- 左のメニューから「ルール」をクリック
  - ルールの一覧から、今回作った「certbotRule」をクリック
  - ルール内容のパネルが表示される
    - リスナーで「myHttpListner」を選択
    - [保存]ボタンをクリック

![ルール編集パネル](/images/azure_appgateway_rule_edit_panel.png =500x)

これで一旦ルーティング規則の設定は終了です。
ルーティングの状態は次のようになっています。

![新ルーティング](/images/azure_appgateway_routing_step2.png)


## certbotによるSSL証明書発行

改めてcertbot用のVM上で操作します。Cloud Shell上から次のコマンドでssh接続してください。（各名称は自分の環境に合わせて設定してください）

```shellsession:CloudShell上
RGNAME="myAGgroup"
SERVERNAME="myVMcertbot"
VMIP=$(az vm show --show-details --resource-group $RGNAME --name $SERVERNAME --query publicIps -o tsv)
ssh azureuser@$VMIP
```

### 証明書を発行

接続したら、certbotを実行します。

```shellsession:certbot用VM上
sudo certbot certonly --nginx
```

- emailアドレスを尋ねられるので入力
- 利用条件を了承するか聞かれるので、（読んでから）「y」と入力
- emailアドレスを共有して良いか聞かれるので、「y]か「n」を入力
- domain nameを聞かれるので、dns名 + リージョンが入ったドメイン名（FQDN)を入力
  - この例では「my-dns-name-2022.japaneast.cloudapp.azure.com」
- 次のように表示さればSSL証明書の発行に成功

```textile:証明書発行結果
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/my-dns-name-2022.japaneast.cloudapp.azure.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/my-dns-name-2022.japaneast.cloudapp.azure.com/privkey.pem
```

メッセージにあるように、「/etc/letsencrypt/live/my-dns-name-2022.japaneast.cloudapp.azure.com/」に証明書ファイルが保存されます

### 証明書の連結

あとで利用するために、作った2つの証明書を連結します。引き続きcertbot用のVM上で操作します。

```shellsession:certbot用VM上
# 作業用ディレクトリ作成
mkdir ~/cert

# 連結
sudo openssl pkcs12 -export \
 -in /etc/letsencrypt/live/my-dns-name-2022.japaneast.cloudapp.azure.com/fullchain.pem \
 -inkey  /etc/letsencrypt/live/my-dns-name-2022.japaneast.cloudapp.azure.com/privkey.pem \
 -out ~/cert/combined.pfx
```

※ _my-dns-name-2022.japaneast.cloudapp.azure.com_ の部分は、自分の環境に合わせて変更してください。

実行するとパスワードを2回聞かれるので、同じ値を指定してください。（※あとで使うので記録しておいてください。

### アクセス権の変更

このあとCloud Shell上にコピーするために、アクセス権を変更します。

```shellsession:certbot用VM上
sudo chmod +r ~/cert/combined.pfx
```

### 証明書の期限

Let's Encryptで発行したSSL証明書の期限は90日です。期限が切れる前に更新する必要がありますが、その方法は別の機会に整理したいと思います。


## HTTPSの設定方法

HTTPSを利用するには、Application GatewayのリスナーにSSL証明書を設定する必要があります。

- (a) 証明書をローカルのダウンロード後、Portal画面からアップロード
- (b) Key Vault経由で設定

今回は(b)のKey Vault経由を使ってみます。

### Key Vaultとは

Key Vault は機密情報を格納する器のサービスです。
公式ページ [Azure Key Vault について](https://learn.microsoft.com/ja-jp/azure/key-vault/general/overview) によると、Key Vaultを使うと次のことが可能です。

- シークレットの管理 
- キー管理 
- 証明書の管理
  - Azure および内部の接続されているリソースで使用するためのパブリックおよびプライベートの Transport Layer Security/Secure Sockets Layer (TLS/SSL) 証明書を簡単にプロビジョニング、管理、デプロイできます

今回のようにSSL証明書の管理にぴったりです。

### azコマンドによるKey Vault作成

certbot用のVMから抜けてCloud Shellに戻り、次のように操作します。（各名称は自分の環境に合わせて変更してください）

```shellsession:CloudShell上
RGNAME="myAGgroup"
VAULTNAME="my-ag-vault"

az keyvault create --name $VAULTNAME --resource-group $RGNAME --location "japaneast"

```

"my-ag-vault" という名前の Key Vault （機密情報を格納する器）ができました。

### ユーザー割り当てマネージド IDの作成

Applicatin GatewayからKey Vaultを利用するために、アクセス権限を付与する仕組みである「ユーザー割り当てマネージド ID（User-assigned managed identity）を利用します。


```shellsession:CloudShell上
RGNAME="myAGgroup"
IDNAME="myCertId"

az identity create --resource-group $RGNAME --name $IDNAME
```

成功すると次のような結果が返ってきます。

```textile
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
  "id": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx/resourcegroups/myAGgroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myCertId",
  "location": "japaneast",
  "name": "myCertId",
  "principalId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyy",
  "resourceGroup": "myAGgroup",
  "tags": {},
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
  "type": "Microsoft.ManagedIdentity/userAssignedIdentities"
}

```

この中の「principalId」を使って、さらに次のように権限を付与します。（シークレットの読み取りと、証明書の一覧/読み取りを許可）

```shellsession:CloudShell上
VAULTNAME="my-ag-vault"
ID="yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyy"

az keyvault set-policy -n $VAULTNAME --secret-permissions get \
--certificate-permissions get list --object-id $ID
```

※IDの値は先ほど結果の「principalId」の値を指定してください。

### 証明書の登録

次はKey Vaultに証明書を登録します。あまりスマートではありませんが、今回はいったんCloud Shell上にコピーしてくることにします。
（リソースグループ名、VM名は自分の環境に合わせて設定してください）

```shellsession:CloudShell上
# 作業用ディレクトリの作成
mkdir ~/cert

# VMのIPアドレスを取得
RGNAME="myAGgroup"
SERVERNAME="myVMcertbot"
VMIP=$(az vm show --show-details --resource-group $RGNAME --name $SERVERNAME --query publicIps -o tsv)

# コピーしてくる
scp azureuser@$VMIP:~/cert/combined.pfx ~/cert
```

次に、azコマンドでKey Vaultに登録します。

```
VAULTNAME="my-ag-vault"
CERTNAME="myAGcert"
PASSWORD="連結に使ったパスワード"

az keyvault certificate import --vault-name $VAULTNAME --name $CERTNAME --password $PASSWORD -f ~/cert/combined.pfx
```

[証明書の連結](https://zenn.dev/mganeko/articles/azure-bootcamp-3-2-dsn-lets-encrypt#証明書の連結)で使ったパスワードを指定してください。もし次のようにエラーが表示されたら、パスワードが間違っている可能性があります。

```textile:エラーメッセージ
We could not parse the provided certificate as .pem or .pfx. Please verify the certificate with OpenSSL
```

### 作業用証明書の削除

作業用に一時的に作成した証明書 ~/cert/combined.pfx は安全のために削除してください。Cloud Shell上、certbot用VM上それぞれで次のように削除してください。

```shellsession
rm ~/cert/combined.pfx
```

## Application GatewayのHTTPS設定

ようやく準備が整いました。Application Gatewayの設定を行い、HTTPS通信ができるようにします。

### リスナーの作成

azコマンドでの指定方法が理解できていないので、Portalの画面からHTTPS(ポート443)用のリスナーを新たに作ります。SSL証明書は先ほどKey Vaultに登録したもの利用します。

Azure Portal上で、作成済みのApplication Gatewayを表示します。

![リスナー](/images/azure_appgateway_add_listener.png =500x)

- 左のメニューから「リスナー」をクリック
- [+リスナーの追加]ボタンをクリック
- 「リスナーの追加」パネルが表示される
  - リスナー名 ... 「myHttpsListner」など（もっと区別しやすい名前が良いかもしれません）
  - フロントエンドIP ... パブリックを選択
  - プロトコル ... HTTPSを選択
  - ポート ... 443
  - HTTPS設定 ... 「キーコンテナから証明書を選択する」
  - 証明書名 ...  「certbotCert」など、好みの名前を指定
  - マネージドID ... [ユーザー割り当てマネージド IDの作成]で作成したID名
  - キーコンテナ名 ... 作成たKey Vaultの名前
  - 証明書 ... 「[証明書の登録](azure-bootcamp-3-2-dsn-lets-encrypt#証明書の登録)」で指定した証明書の名前（CERTNAMEの値）
  - その他 ... デフォルトのまま
  - [追加]ボタンをクリック
- Application Gatewayの画面に戻る

![HTTPSリスナー](/azure_appgateway_https_listener_concat.png =500x)


### ルーティング規則の変更

最後にルーティング規則を変更し、HTTPS用のリスナーを利用します。引き続きAzure Portal上でApplication Gatewayの設定を行います。

![ルール](/images/azure_appgateway_rule.png =500x)

- 左のメニューから「ルール」をクリック
- 「リスナー」タブを選択
  - リスナー ... 先ほど作った「myHttpsListener」を選択
- [保存]ボタンをクリック


![ルール](/images/azure_appgateway_https_rule_https.png =500x)

しばらく待つと（数十秒？）設定が反映され、次の状態になります。これでHTTPSの設定は完了です。

![ルール](/images/azure_appgateway_routing_step3.png)

### ブラウザからの確認

ブラウザからHTTPSでアクセスできるようになったはずです。

- https://_指定したDNS名_.japaneast.cloudapp.azure.com/


# まとめ

Let's Encrypt を使って Application Gateway をHTTPSで通信できるようになりました。一方、証明書の更新処理が課題として残っていますが、それは別の記事で整理する予定です。

# シリーズの記事一覧

- 0. [このシリーズについて](azure-bootcamp-0-about)
- 1. [Azure Portalを使って、ブラウザからVMを起動する](azure-bootcamp-1-vm-by-portal)
- 2. [CLIを使って、コマンドでVMを起動する](azure-bootcamp-2-vm-by-cli)
- 3. [Application Gatewayを使ったVMの簡易Blue-Greenデプロイ](azure-bootcamp-3-application-gateway)
- 3.1. [ARMテンプレートを使ったApplication Gatewayのデプロイ](azure-bootcamp-3-1-appgateway-by-arm)
- 3.2. [Application GatewayのDNSの指定とHTTPS化](azure-bootcamp-3-2-dsn-lets-encrypt)
