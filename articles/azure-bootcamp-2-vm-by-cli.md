---
title: "Azure Self-Study 2 - Azure CLIを使って、コマンドでVMを起動する" # 記事のタイトル
emoji: "🌩️" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["azure"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---

# はじめに：CLIを使ってみよう

この記事では、AzureのCLI（コマンドラインインターフェイス）を使って、VMの起動とWebサーバーのセットアップを行います。（コマンドの使い方は2022年8月時点のものです）

コマンドラインから各種操作を行うことが、さまざまな自動化の入り口になります。

こちらの公式サイトの内容をベースにしています。

- [クイック スタート:Azure CLI で Linux 仮想マシンを作成する](https://docs.microsoft.com/ja-jp/azure/virtual-machines/linux/quick-create-cli)

# azコマンド: Auzre の CLI

Azureのコマンドラインインターフェイス(CLI)は「az」コマンドです。インストール方法は公式サイトを参照するのが確実です。

- [Azure CLI をインストールする方法](https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli)

CLIは次の環境で利用できます。

- Windows、macOS、および Linux 環境
- Dockerコンテナ
- Azure Cloud Shell ... Azure Potal上で利用できるコンソール機能

今回は一番手軽な「Azure Cloud Shell」を使います。（CLIのインストール不要）

# Cloud Shellの開始

- [Azure Potarl](https://portal.azure.com/) にサインイン
- ポータル画面の一番上、検索エリアのすぐ右の「Cloud Shell」ボタンをクリック

![新規リソース](/images/azure_cloud_shell_button.png)

- 初めてCloud Shellを使う場合は、「ストレージが必要、作るか？」といった趣旨の確認が出るので、OKして継続
  - cloud-shell-storage-_xxxx_ というリソースグループが作成され
  - その中に専用のディスク領域が準備される
- ブラウザの下部にターミナル領域が表示される
  - 「CBL-Mariner/Linux」が起動される … マイクロソフト開発のLinuxディストリビューション

![新規リソース](/images/azure_cloud_shell.png)

## CLI コマンドの確認

Cloud Shell上で、次のコマンドを実行し、azコマンドが動くことを確認します。


```shellsession
az version
```

実行すると、次のようにバージョン情報が表示されます。

```textile
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

azコマンドの詳細は、公式リファレンスを参照してください

- https://docs.microsoft.com/ja-jp/cli/azure/reference-index?view=azure-cli-latest


# CLIでリソースグループを作成

Cloud Shell上で、CLI(azコマンド)を使って、リソースグループを作成します。この例では作成するリソースグループ名を「myCLIgroup」とします。

```shellsession
az group create --name myCLIgroup --location japaneast
```

ここでオプション指定は次の通りです。

- --name リソーグループ名を指定
- --location 作成する地域を指定

作成が完了すると、次のように結果が表示されます。

```textile
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

実行したら、リソースグループが作成されたことをポータル画面でも確認してください。

# CLIでVMを起動

## VMの作成

次はVMを作成して起動します。Cloud Shellからazコマンドを実行します。

```shellsession
az vm create \
  --resource-group myCLIgroup \
  --name myVM \
  --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest \
  --size Standard_B1ls \
  --public-ip-sku Standard \
  --storage-sku StandardSSD_LRS \
  --nic-delete-option Delete \
  --os-disk-delete-option Delete \
  --admin-username azureuser \
  --generate-ssh-keys
```

ここでオプション指定は次の通りです。

- --resource-group ... VMを作るリソーグループ名を指定
- --name ... VMの名前
- --image ... 元にするOSのイメージ。ここではUbuntu 20.04 LTS-gen2を指定
  - ※単に UbuntuLTS だと、Ubuntu 18.04 LTSになる (2022年8月現在)
- --size ... VMのサイズ。ここではメモリ0.5GiBの小さなサイズを指定
- --public-ip-sku ... パブリックIPアドレスの種類
- --storage-sku ... ストレージの種類
- --nic-delete-option ... VM削除時にネットワークインターフェイスを消すか
  - 今回は一緒に削除（Delete)
- --os-disk-delete-option ... VM削除時にOS用ディスクを消すか
  - 今回は一緒に削除（Delete)
- --admin-username ... 管理ユーザーの名前
- --generate-ssh-keys ... ssh鍵を新しく作る（既存のものを使うことも可能）

作成には1分程度かかります。実行すると次のような結果が返ってきます。

```textile
{
  "fqdns": "",
  "id": "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/myCLIgroup/providers/Microsoft.Compute/virtualMachines/myVM",
  "location": "japaneast",
  "macAddress": "xx-xx-xx-xx-xx-xx",
  "powerState": "VM running",
  "privateIpAddress": "10.0.0.x",
  "publicIpAddress": "xxx.xxx.xxx.xxx",
  "resourceGroup": "myCLIgroup",
  "zones": ""
}
```

「publicIpAddress」がインターネット側に公開されるパブリックIPアドレスです。後で使うのでこれを記録しておきます。

## VMのパブリックIPアドレスの確認

次のコマンドでVMのIPアドレスを確認することができます。リソースグループ名が「myCLIgroup」、VM名が「myVM」の場合は次の通りです。

```shellsession
az vm show --show-details --resource-group myCLIgroup --name myVM --query publicIps -o tsv
```

後で利用できるように、Cloud Shell上で環境変数に設定しておきましょう。

```shellsession
VMIP=$(az vm show --show-details --resource-group myCLIgroup --name myVM --query publicIps -o tsv)
echo $VMIP
```

:::message
時間があいて Cloud Shellのセッションが切断されると、環境変数はクリアされます。その場合は再度設定してから後続の手順に進んでください。
:::

## VMに接続確認

作成したVMに接続できることを確認します。Cloud ShellからVMを作成した場合、SSHの秘密鍵は自動的に保存されるので、すぐに接続することができます。

```shellsession
ssh azureuser@$VMIP
```

初回の接続時は「Are you sure you want to continue connecting (yes/no/[fingerprint])? 」と聞かれるので、「yes」と入力して続行してください。

接続できたら「exit」とコマンドを打って、Cloud Shellに戻ります。


# Webサーバー(nginx)のセットアップ

リソースグループ名が「myCLIgroup」、VM名が「myVM」とします。

## nginxのインストール

次にVMのアップデートと、Webサーバー(nginx)のインストールを行います。実行には数分かかります。

```shellsession
az vm run-command invoke \
  --resource-group myCLIgroup \
  --name myVM \
  --command-id RunShellScript \
  --scripts "sudo apt update && sudo apt upgrade -y && sudo apt-get install -y nginx"
```

ここでオプション指定は次の通りです。

- --resource-group ... VMの所属するリソーグループ名を指定
- --name ... VMの名前
- --command-id ... 実行するコマンドの種類
- --scripts ... 実行するコマンド
  - ここでは、パッケージの更新とnginxのインストールを実行


## httpポートの公開

インターネットからアクセスできるように、Cloud Shellからhttp(80)ポートを公開します。

```shellsession
az vm open-port --port 80 --resource-group myCLIgroup --name myVM
```

- --port ... アクセスを許可するポート番号。ここでは80番(HTTP) 
- --resource-group ... VMの所属するリソーグループ名を指定
- --name ... VMの名前

数十秒待つとポートの公開が完了します。
このままCloud Shellからcurlコマンドでアクセスして確認します。

```shellsession
curl http://$VMIP
```

下記のような結果が表示さればOKです。

```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        ... 省略 ...
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

... 省略 ...

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## ブラウザから確認

ブラウザでもアクセスできるか確認してみましょう。

- http//_VMのIPアドレス_/

次のように表示さればOKです。

![nginxデフォルト](/images/azure_nginx_default_page.png)


## ページの追加

ページ追加も試してみましょう。Cloud Shellから次のコマンドを実行します。


```shellsession
az vm run-command invoke \
  --resource-group myCLIgroup \
  --name myVM \
  --command-id RunShellScript \
  --scripts "sudo echo '<html><body><H2>Hello Azure<h2></body></html>' > /var/www/html/hello.html"
```

完了したら、ブラウザからアクセスできるか確認してみましょう。

- http//_VMのIPアドレス_/hello.html

「Hello Azure」と表示されればOKです。


# DNSの設定

パブリックIPアドレスに対して、DNS名を設定してみましょう

## パブリックIPの名前を取得

まずパブリックIPの名前を取得し環境変数にセットします。

```shellsession
IPNAME=$(az network public-ip list --resource-group myCLIgroup --query "[?ipAddress=='$VMIP'].{name: name}" -o tsv)
echo $IPNAME
```

## DNS名を指定

次にDNS名を指定します。例えば「_my-dns-name-2022_」を指定する場合は次のコマンドを実行します。

```shellsession
az network public-ip update --resource-group myCLIgroup -n $IPNAME --dns-name my-dns-name-2022 
```

ここで「_my-dns-name-2022_」の部分はその地域（リージョン）で一意となる（他のユーザーのつける名前と重ならない）ように、名前を選んでください。

## DNSの指定を確認

Cloud Shellから次のコマンドを実行します。

```shellsession
az network public-ip list -g myCLIgroup --query "[?ipAddress=='$VMIP'].{name: name, fqdn: dnsSettings.fqdn, address: ipAddress}"
```

次のような結果が表示されればOKです。

```textile
[
  {
    "address": "xxx.xxx.xxx.xxx",
    "fqdn": "つけた名前.japaneast.cloudapp.azure.com",
    "name": "パブリックIPの名前"
  }
]
```

## ブラウザでアクセス

次のURLにブラウザでアクセスし、デフォルトページが表示されればOKです。

- http://_つけた名前_.japaneast.cloudapp.azure.com/ (japan eastに作っている場合)



# VM削除

VMの削除もコマンドで実行できます。リソースグループ名が「myCLIgroup」、VM名が「myVM」の場合は次の通りです。

```shellsession
az vm delete --resource-group myCLIgroup --name myVM
```

「Are you sure you want to perform this operation? (y/n):」と確認を求められるので、「y [enter]」と入力して削除を実行します。

VMが削除されても、次のリソースが残ります。

- ネットワーク セキュリティ グループ
- パブリック IP アドレス
- 仮想ネットワーク(VNET)


# シェルスクリプトでVM再作成

次の前提のもと、シェルスクリプトで一連の処理（VMの作成〜Webサーバーのインストールまで）を実行します。

- リソースグループ作成済み
- パブリックIP作成済み
- 仮想ネットワーク(VNET)がある
- ネットワークセキュリティグループで、HTTP(80)ポートを許可済み

## シェルスクリプトの内容

エディタを使い、setup_web_vm.sh を次の内容で作成してください。（グルーバル変数を使っていて行儀が悪いコードですが、ご容赦ください）

```shell:setup_web_vm.sh
#!/bin/sh
#
# setup_web_vm.sh
#
# usage:
#   sh setup_web_vm.sh resorucegoupname vmname

# ============= functions ==============

# -- check args (must be 2) --
function checkArgs() {
  if [ $1 -ne 2 ]; then
    echo "ERROR: Please specify ResourceGroupName and VMName (2 args)."
    exit 1
  fi
}

# -- get PubliIP name --
function getPublicIP() {
  IPNAME=$(az network public-ip list -g $RGNAME --query "[?ipConfiguration == null].{name: name}" --output tsv)

  if [ -n "$IPNAME" ]; then
    echo "PublicIP found:" $IPNAME
  else
    echo "ERROR: Available PublicIP NOT FOUND."
    exit 2
  fi
}

# -- get NSG name --
getNetworkSecurityGroup() {
  NSG=$(az network nsg list --resource-group $RGNAME --query "[].{name: name}" --output tsv)

  if [ -n "$NSG" ]; then
    echo "Network Security Group found:" $NSG
  else
    echo "ERROR: Available Network Security Group NOT FOUND."
    exit 2
  fi
}

# -- create VM ---
function createVM() {
  echo "-- creating VM name=" $VMNAME " --"
  az vm create \
    --resource-group $RGNAME \
    --name $VMNAME \
    --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest \
    --size Standard_B1ls \
    --public-ip-address $IPNAME \
    --public-ip-sku Standard \
    --nsg $NSG \
    --storage-sku StandardSSD_LRS \
    --nic-delete-option Delete \
    --os-disk-delete-option Delete \
    --admin-username azureuser \
    --generate-ssh-keys
  RET=$?

  if [ $RET -ne 0 ]; then
    echo "ERROR: create VM result=" $RET
    exit $RET
  fi

  echo "create VM Success"
  echo ""
  return $RET
}

# -- update VM --
function updateVM() {
  echo "-- update VM name=" $VMNAME " --"
  az vm run-command invoke \
    --resource-group $RGNAME \
    --name $VMNAME \
    --command-id RunShellScript \
    --scripts "sudo apt update && sudo apt upgrade -y"
  echo "update VM result:" $?
  echo ""
}

# -- install nginx --
function installNginx() {
  echo "-- install Nginx --"
  az vm run-command invoke \
    --resource-group $RGNAME \
    --name $VMNAME \
    --command-id RunShellScript \
    --scripts "sudo apt-get install -y nginx"
  RET=$?

  if [ $RET -ne 0 ]; then
    echo "ERROR: install nginx result=" $RET
    exit $RET
  fi

  echo "install nginx Success"
  echo ""
  return $RET
}

# -- web access check --
function webAccessCheck() {
  IPADDR=$(az network public-ip show --resource-group $RGNAME --name $IPNAME --query  ipAddress -o tsv)
  echo "IP address=" $IPADDR
  echo "-- access test: curl http://$IPADDR --"
  curl http://$IPADDR
  RET=$?

  echo "curl result:" $RET
  echo ""

  return $RET
}

# ============= main ==============

# -- args --
ARGNUM=$#
checkArgs $ARGNUM

RGNAME=$1
VMNAME=$2
IPNAME=""
NSG=""

echo "ResourceGroup Name=" $RGNAME
echo "VM Name=" $VMNAME
echo ""

# -- get PubliIP name --
getPublicIP

# -- get NSG name --
getNetworkSecurityGroup
echo ""

# -- create VM ---
createVM

# -- update VM --
updateVM

# -- install nginx --
installNginx

# -- web access check --
webAccessCheck


# -- finish --
echo "==== setup VM:" $VMNAME " and Web(nginx) DONE ===="
echo ""

exit 0

```

## シェルスクリプトの実行

用意したリソースグループ名、今回作成するVM名を引数に指定して起動します。実行には数分かかります。

例) リソースグループ名:myCLIgroup、作成するVM名:myWebVM の場合

```shellsession
sh setup_web_vm.sh myCLIgroup myWebVM
```

残っていたパブリックIPアドレス、DNS名を引き継いでいるので、ブラウザからアクセスして確認してください。

- http://_つけた名前_.japaneast.cloudapp.azure.com/ (japan eastに作っている場合)



# シェルスクリプトでVM削除

## 削除用スクリプト

VMを削除するシェルスクリプトは次の通りです。エディタで　「delete_vm.sh」として作成してください。

```shell:delete_vm.sh
#!/bin/sh
#
# delete_vm.sh
#
# usage:
#   sh delete_vm.sh resorucegoupname vmname

# -- param --
RGNAME=$1
VMNAME=$2
echo "ResourceGroup Name=" $RGNAME
echo "VM Name=" $VMNAME
echo ""

# -- delete VM ---
echo "-- deleting VM name=" $VMNAME " --"
az vm delete --resource-group $RGNAME --name $VMNAME
echo "delete VM result:" $?
echo ""

```

## シェルスクリプトの実行

対象のリソースグループ名、削除するするVM名を引数に指定して起動します。

例) リソースグループ名:myCLIgroup、削除するVM名:myWebVM の場合

```shellsession
sh delete_vm.sh myCLIgroup myWebVM
```

「Are you sure you want to perform this operation? (y/n):」と確認を求められるので、「y」と答えて削除実行してください。



# 全てのリソースの削除

最後に後片付けとして、リソースグループごと全てのリソースを削除します。リソースグループ名が「myCLIgroup」の場合は次の通りです。

```shellsession
az group delete --name myCLIgroup
```

「Are you sure you want to perform this operation? (y/n):」と確認を求められるので、「y」と答えて削除実行してください。


# まとめ/次回予告

AzureでVMを作る/削除する操作を、コマンドラインインターフェイスの az コマンドを使って実施しました。次はロードバランサーの一種であるApplication Gatewayを使って、簡易的なBlue/Greenデプロイ（サービスを止めずに切り替えるデプロイ方法）をやってみる予定です。


# シリーズの記事一覧

- 0. [このシリーズについて](azure-bootcamp-0-about)
- 1. [Azure Portalを使って、ブラウザからVMを起動する](azure-bootcamp-1-vm-by-portal)
- 2. [CLIを使って、コマンドでVMを起動する](azure-bootcamp-2-vm-by-cli)
- 3. [Application Gatewayを使ったVMの簡易Blue-Greenデプロイ](azure-bootcamp-3-application-gateway)
- 3.1. [ARMテンプレートを使ったApplication Gatewayのデプロイ](azure-bootcamp-3-1-appgateway-by-arm)
- 3.2. [Application GatewayのDNSの指定とHTTPS化](azure-bootcamp-3-2-dsn-lets-encrypt)

