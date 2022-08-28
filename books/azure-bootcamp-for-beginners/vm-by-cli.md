---
title: "Azure CLIを使って、コマンドでVMを起動する" # 記事のタイトル
published: false # 公開設定（falseにすると下書き）
---

# CLIを使ってみよう

この章では、AzureのCLI（コマンドラインインターフェイス）を使って、VMの起動とWebサーバーのセットアップを行います。（コマンドの使い方は2022年8月時点のものです）

コマンドラインから各種操作を行うことが、さまざまな自動化の入り口になります。

こちらの公式サイトの内容をベースにしています。

- [クイック スタート:Azure CLI で Linux 仮想マシンを作成する](https://docs.microsoft.com/ja-jp/azure/virtual-machines/linux/quick-create-cli)

## azコマンド: Auzre の CLI

Azureのコマンドラインインターフェイス(CLI)は「az」コマンドです。インストール方法は公式サイトを参照するのが確実です。

- [Azure CLI をインストールする方法](https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli)

CLIは次の環境で利用できます。

- Windows、macOS、および Linux 環境
- Dockerコンテナ
- Azure Cloud Shell ... Azure Potal上で利用できるコンソール機能

今回は一番手軽な「Azure Cloud Shell」を使います。（CLIのインストール不要）

## Cloud Shellの開始

- [Azure Potarl](https://portal.azure.com/) にサインイン
- ポータル画面の一番上、検索エリアのすぐ右の「Cloud Shell」ボタンをクリック

![新規リソース](/images/azure_cloud_shell_button.png)

- 初めてCloud Shellを使う場合は、「ストレージが必要、作るか？」といった趣旨の確認が出るので、OKして継続
  - cloud-shell-storage-_xxxx_ というリソースグループが作成され
  - その中に専用のディスク領域が準備される
- ブラウザの下部にターミナル領域が表示される
  - 「CBL-Mariner/Linux」が起動される … マイクロソフト開発のLinuxディストリビューション

![新規リソース](/images/azure_cloud_shell.png)

### CLI コマンドの確認

Cloud Shell上で、次のコマンドを実行し、azコマンドが動くことを確認します。


```
az version
```

実行すると、次のようにバージョン情報が表示されます。

```
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


## CLIでリソースグループを作成

Cloud Shell上で、CLI(azコマンド)を使って、リソースグループを作成します。この例では作成するリソースグループ名を「myCLIgroup」とします。

```
az group create --name myCLIgroup --location japaneast
```

ここでオプション指定は次の通りです。

- --name リソーグループ名を指定
- --location 作成する地域を指定

作成が完了すると、次のように結果が表示されます。

```
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

## CLIでVMを起動

### VMの作成

次はVMを作成して起動します。Cloud Shellからazコマンドを実行します。

```
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

```
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

### VMのパブリックIPアドレスの確認

次のコマンドでVMのIPアドレスを確認することができます。

```
az vm show --show-details --resource-group myCLIgroup --name myVM --query publicIps -o tsv
```

後で利用できるように、Cloud Shell上で環境変数に設定しておきましょう。

```
VMIP=$(az vm show --show-details --resource-group myCLIgroup --name myVM --query publicIps -o tsv)
echo $VMIP
```

### VMに接続確認

作成したVMに接続できることを確認します。Cloud ShellからVMを作成した場合、SSHの秘密鍵は自動的に保存されるので、すぐに接続することができます。

```
ssh azureuser@$VMIP
```

初回の接続時は「Are you sure you want to continue connecting (yes/no/[fingerprint])? 」と聞かれるので、「yes」と入力して続行してください。

接続できたら「exit」とコマンドを打って、Cloud Shellに戻ります。

## Webサーバー(nginx)のセットアップ

### nginxのインストール

次にVMのアップデートと、Webサーバー(nginx)のインストールを行います。実行には数分かかります。

```
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


### httpポートの公開

インターネットからアクセスできるように、Cloud Shellからhttp(80)ポートを公開します。

```
az vm open-port --port 80 --resource-group myCLIgroup --name myVM
```

- --port ... アクセスを許可するポート番号。ここでは80番(HTTP) 
- --resource-group ... VMの所属するリソーグループ名を指定
- --name ... VMの名前

数十秒待つとポートの公開が完了します。
このままCloud Shellからcurlコマンドでアクセスして確認します。

```
curl http://$VMIP
```

下記のような結果が表示さればOKです。

```
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

### ブラウザから確認

ブラウザでもアクセスできるか確認してみましょう。

- http//_VMのIPアドレス_/

次のように表示さればOKです。

![nginxデフォルト](/images/azure_nginx_default_page.png)


### ページの追加

## DNSの設定

パブリックIPアドレスに対して、DNS名を設定します。

```
IPNAME=$(az network public-ip list --resource-group myCLIgroup --query "[?ipAddress=='$VMIP'].{name: name}" -o tsv)
echo $IPNAME
```

dnsを指定

```
az network public-ip update --resource-group myCLIgroup -n $IPNAME --dns-name my-dns-name-2022 
```

「_my-dns-name-2022_」の部分はその地域（リージョン）で一意となる（他のユーザーのつける名前と重ならない）ように、名前を選んでください。

確認

```
az network public-ip list -g myCLIgroup --query "[?ipAddress=='$VMIP'].{name: name, fqdn: dnsSettings.fqdn, address: ipAddress}"
```

ブラウザでアクセス

- http://_つけた名前_.japaneast.cloudapp.azure.com/ (japan eastに作っている場合)

## VM削除

```
az vm delete --resource-group myCLIgroup --name myVM
```

「Are you sure you want to perform this operation? (y/n):」と確認を求められるので、「y [enter]」と入力して削除を実行します。

VMが削除されても、次のリソースが残ります。

- ネットワーク セキュリティ グループ
- パブリック IP アドレス
- 仮想ネットワーク(VNET)

## シェルスクリプトでVM再作成

次の前提のもと、シェルスクリプトで一連の処理（VMの作成〜Webサーバーのインストールまで）を実行します。

- リソースグループ作成済み
- パブリックIP作成済み
- 仮想ネットワーク(VNET)がある
- ネットワークセキュリティグループで、HTTP(80)ポートを許可済み

### シェルスクリプトの内容

setup_web_vm.sh

```
#!/bin/sh
#
# setup_web_vm.sh
#
# usege:
#   sh setup_web_vm.sh resorucegoupname vmname

# -- param --
if [ $# -ne 2 ]; then
  echo "ERROR: Please specify ResourceGroupName and VMName (2 args)."
  exit 1
fi

RGNAME=$1
VMNAME=$2
IPNAME=""
NSG=""

echo "ResourceGroup Name=" $RGNAME
echo "VM Name=" $VMNAME
echo ""

# -- get PubliIP name --
IPNAME=$(az network public-ip list -g $RGNAME --query "[?ipConfiguration == null].{name: name}" --output tsv)

if [ -n "$IPNAME" ]; then
  echo "PublicIP found:" $IPNAME
else
  echo "ERROR: Available PublicIP NOT FOUND."
  exit 2
fi

# -- get NSG name --
NSG=$(az network nsg list --resource-group $RGNAME --query "[].{name: name}" --output tsv)

if [ -n "$NSG" ]; then
  echo "Network Security Group found:" $NSG
else
  echo "ERROR: Available Network Security Group NOT FOUND."
  exit 2
fi

#echo "ResourceGroup Name=" $RGNAME
#echo "VM Name=" $VMNAME
#echo "PublicIP Name=" $IPNAME
#echo "Network Security Group=" $NSG
echo ""

# -- create VM ---
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

echo "create VM result:" $?
echo ""


# -- update VM --
echo "-- update VM name=" $VMNAME " --"
az vm run-command invoke \
  --resource-group $RGNAME \
  --name $VMNAME \
  --command-id RunShellScript \
  --scripts "sudo apt update && sudo apt upgrade -y"
echo "update VM result:" $?
echo ""

# -- install nginx --
echo "-- install Nginx --"
az vm run-command invoke \
  --resource-group $RGNAME \
  --name $VMNAME \
  --command-id RunShellScript \
  --scripts "sudo apt-get install -y nginx"
echo "install nginx result:" $?
echo ""

# -- access check --
IPADDR=$(az network public-ip show --resource-group $RGNAME --name $IPNAME --query  ipAddress -o tsv)
echo "IP address=" $IPADDR
echo "-- access test: curl http://$IPADDR --"
curl http://$IPADDR
echo "curl result:" $?
echo ""


# -- finish --
echo "==== setup VM:" $VMNAME " and Web(nginx) DONE ===="
echo ""

exit 0

```

### シェルスクリプトの実行

用意したリソースグループ名、今回作成するVM名、作成済みのパブリックIPの名前、作成済みのネットワークセキュリティグループの名前、を指定して起動します。

例)

```
sh setup_web_vm.sh myCLIgroup myWebVM myVMPublicIP myVMNSG
```




## シェルスクリプトでVM削除

```
#!/bin/sh
#
# delete_vm.sh
#
# usege:
#   sh delete_vm.sh resorucegoupname vmname

# -- param --
RGNAME=$1
VMNAME=$2
echo "ResourceGroup Name=" + $RGNAME
echo "VM Name=" + $VMNAME
echo ""

# -- delete VM ---
echo "-- deleting VM name=" $VMNAME " --"
az vm delete --resource-group $RGNAME --name $VMNAME
echo "delete VM result:" $?
echo ""

```



## 全てのリソースの削除

最後に後片付けとして、リソースグループごと全てのリソースを削除します。

```
az group delete --name myCLIgroup
```

「Are you sure you want to perform this operation? (y/n):」と確認を求められるので、「y」と答えて削除実行してください。


## まとめ/次回予告

AzureでVMを作る/削除する操作を、コマンドラインインターフェイスの az コマンドを使って実施しました。次はロードバランサーの一種であるApplication Gatewayを使って、簡易的なBlue/Greenデプロイ（サービスを止めずに切り替えるデプロイ方法）をやってみる予定です。


