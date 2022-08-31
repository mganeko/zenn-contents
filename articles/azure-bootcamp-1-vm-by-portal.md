---
title: "Azure Bootcamp 1 - Azure Portalを使って、ブラウザからVMを起動する" # 記事のタイトル
emoji: "💻" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["azure"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# VMを起動しよう

この記事では、Azureのポータル（Web画面）を使って、VMを起動してWebサーバーを動かしてみます。（画面操作は2022年8月時点のものです）

こちらの公式サイトの内容をベースにしています。

- [クイック スタート:Azure portal で Linux 仮想マシンを作成する](https://docs.microsoft.com/ja-jp/azure/virtual-machines/linux/quick-create-portal)


## 準備：リソースグループ

AuzreではVMなどの色々なサービスの要素（リソース）をまとめて管理する仕組みとして「リソースグループ」を使います。

今回の実験のために、まずリソースグループを作りましょう。

### ポータルからリソースグループを作成

- [Azure Potarl](https://portal.azure.com/) にサインイン
- 「リソースグループ」で検索し、リソースグループのページに移動
- [+新規]をクリック

![新規リソース](/images/azure_resouce_group_head.png =400x)

- リソースグループの新規作成画面が表示されるので、次の項目を指定
  - サブスクリプションを選択 ... 課金単位をまとめるもの
    - アカウント作成時に作っているはず。複数ある場合は今回利用するものを選択
  - リソースグループ ... 今回作る任意の名前を指定
    - この例では「_myVMgroup_」を指定。今後自分の指定した名前に読み替えてください
  - リージョン ... リソースを作成する地域。好みの地域を選択
    - この例では「Japan East」を指定（一覧に見当たらない場合は、Japanを入力して候補を検索）

![リソースグループの内容](/images/azure_new_resource_group.png)

- 画面の下の[確認および作成]ボタンをクリック
- 確認画面で内容を確認し、OKなら下の[作成]ボタンをクリック
- リソースグループの一覧画面に戻る
  - 指定した「_myVMgroup_」が一覧に存在するのを確認

この後のリソース(VM等)は、今回用意したリソースグループ「_myVMgroup_」に作ります。

## VMの起動

次にポータルからVMを作成します。

### ポータルからVMの作成

- ポータルで「Virtual Machines」を検索し、Virtual Machinesのページに移動
- [+新規]をクリック
  - 出てきたメニューから[Azure 仮想マシン]をクリック

![新規VMメニュー](/images/azure_vm_menu.png =300x)

### 基本内容の指定

- 「仮想マシンの作成」画面が表示されるので、次の項目を指定
  - サプスクリプション
  - リソースグループ ... 準備で作成したリソースグループを選択（ _myVMgroup_ など）
  - 仮想マシン名 ... 作成するVMの名前。任意に指定（例えば _firstVM_ など）
  - 地域 ... Japan Eastなど
  - イメージ ... OSの種類。今回は「Ubuntu Server 20.04LTS - Gen2」を選択
    - ※選択が反映されない場合は、一度たのイメージを洗濯してから、再度「Ubuntu Server 20.04LTS - Gen2」を選択

![新規VM指定1](/images/azure_new_vm_panel1.png)

- 続き
  - サイズ ... VMのサイズ。今回は「Standard_B1ls - 1 vcpu、0.5GiB のメモリ」を選択
  - 管理者アカウントの設定はそのまま
    - 認証の種類 ... SSH公開キー
    - ユーザー名 ... azureuser
    - SSH公開キーのソース ... 新しいキーの組みの生成
    - キーの組名 ... この例では「_firstVM_key_」

![新規VM指定2](/images/azure_new_vm_panel2.png)

- さらに続き
  - 受信ポートの規則はそのまま（sshでの接続を許可する）
    - パブリック受信ポート ... 選択したポートを許可する
    - 受信ポートを選択 ... SSH(22)
- 下の[次：ディスク]ボタンをクリック

### ディスクの指定

- OSディスクの種類 ... (1ランク下げて)「Standard SSD」を選択
- データディスク ... 追加しない（そのまま）
- 下の[次：ネットワーク]ボタンをクリック

![新規VMディスク](/images/azure_new_vm_disk_panel.png)

### ネットワークの指定

- 内容はデフォルトのまま（sshの接続を許可する）
- 下の[確認および作成]ボタンをクリック

![新規VMネットワーク](/images/azure_new_vm_network_panel.png)

### 確認と作成

- 指定内容を確認したら、[作成]ボタンをクリック

![新規VM確認](/images/azure_new_vm_confirm_panel.png)

- 「新しいキーの組の生成」ダイアログが表示される
  - [秘密キーのダウンロードとリソースの作成]ボタンをクリック
- ブラウザーで秘密キーのファイルがダウンロードされる
  - この例では「firstVM_key.pem」
  - 後で利用するので、適切なディレクトリに移動
    - MacやLinuxの場合はユーザのホームの直下の「.ssh」フォルダなど（~/.ssh/）
    - Windowsの場合もホームディレクトリの下に「.ssh」フォルダを作って移動
- デプロイが開始
  - 数十秒かかる
  - 完了すると[リソースに移動]ボタンが表示されるので、クリック
- 作成されたVMの概要が表示される
  - 「パブリック IP アドレス」の値を記録しておく（この後で利用するため）

![VM情報](/images/azure_vm_basic_info.png)

## VMに接続

起動したVMに、sshやターミナルエミュレーターで接続します。

### MacやLinuxの場合

ターミナルを開き、次のように秘密キーのパーミッション（アクセス権限）を変更してから、sshで接続します。

```
chmod 600  ~/.ssh/firstVM_key.pem

ssh -i ~/.ssh/firstVM_key.pem azureuser@xxx.xxx.xxx.xxx
```

- _~/.ssh/firstVM_key.pem_ の部分は、実際に保存した秘密キーのパスを指定
- _xxx.xxx.xxx.xxx_ の部分は、先ほど記録した「パブリック IP アドレス」を指定
- 初回に接続する際には、「接続を続行するか(Are you sure you want to continue connecting?) 」等の確認メッセージが出るので、Yes/OKして進む


### Windowsの場合

コマンドプロンプト、またはPower Shellを開き、次の様にsshで接続します。

```
ssh -i C:\Users\username\.ssh\firstVM_key.pem azureuser@xxx.xxx.xxx.xxx
```

- _C:\Users\username\\.ssh\firstVM_key.pem_ の部分は、実際に保存した秘密キーのパスを指定
- _xxx.xxx.xxx.xxx_ の部分は、先ほど記録した「パブリック IP アドレス」を指定
- 初回に接続の際に確認メッセージが出るので、Yes/OKして進む　（※実際のメッセージを確認）

あるいは、「[RLogin](https://kmiya-culti.github.io/RLogin/)」等のターミナルエミュレーターを利用してもOKです。（秘密キーのファイルを指定して接続）


## Webサーバー(nginx)のインストール

VMに接続できたら、その状態でWebサーバ([nginx](https://www.nginx.com/resources/wiki/))をインストールして動かします。
※手物とのマシン(Mac/Linux/Windows)ではなく、先ほど接続したVMに対して操作します。

### nginxとは

- オープンソースのWebサーバー
- リバースプロキシ、ロードバランサ機能を持つ
- 処理性能や並行性が高い、メモリ使用量が小さい
- Apacheを超えるシェア


### VMのパッケージを更新

```
sudo apt update && sudo apt upgrade -y
```

### nginxのインストール

```
sudo apt install nginx -y
ps -ef | grep nginx
```

ここでnginxのプロセスがいくつか表示されればOKです。（おそらく2つ）

![nginx開始](/images/azure_start_nginx.png)


インストールが終わると、上記のように自動的に起動します。また関連するファイルは次の場所に保管されています。

- 実行バイナリ ... /usr/sbin/nginx
- 設定ファイル ... /etc/nginx/
- HTMLファイル ... /var/www/html/


### httpポートの公開

Azureの持つネットワークの保護機能により、このままではhttpポート(80/tcp)は外部からアクセスアクセスできません。そこで、ポータル画面がから明示的にアクセスを許可します。

- Azureのポータル画面で、作成したVMを選択
- 左のメニューから「ネットワーク」をクリック
- 「受信ポートの規則」タブで[受信ポートの規則を追加する]ボタンをクリック

![ネットワーク](/images/azure_vm_network.png)

- 受信セキュリティパネルで内容を選択
  - ソース ... Any（そのまま）
  - ソースポート ... * （そのまま）
  - 宛先 ... Any（そのまま）
  - **サービス ... HTTPを選択**
  - 宛先ポート範囲 ... 80で固定
  - プロトコル ... TCPで固定
  - アクション ... 許可
  - 優先度 ... 任意（この例では310、デフォルトのまま）
  - 名前 ... 任意のわかりやすい名前（この例では Port_80）
- [追加]ボタンをクリック

![受信規則1](/images/azure_port_rule1.png =400x)

![受信規則2](/images/azure_port_rule2.png =400x)

- しばらく経つと受信ポート規則が追加される（反映されない場合はリロード）

### ブラウザでのアクセス確認

- ブラウザでアクセス
  - http://_作成したVMのIPアドレス_/
- 下記のようにデフォルトのページが表示されればOK
  - 初回は10秒以上時間がかかったり、タイムアウトする場合もあり
  - その時はリロードして再確認

![nginxデフォルト](/images/azure_nginx_default_page.png)


### HTMLファイルを追加
次に、HTMLファイルを追加してみましょう。
VMのターミナルで操作してください。

htmlのディレクトリに移動

```
cd /var/www/html
```


エディターでファイルを編集(vi/vim, emacs, nano等で好きなものを利用してください）

```
sudo vi hello.html
```

好きな内容で良いですが、例えば次のようなものでOKです。

hello.htmlの内容

```html:hello.html
<!DOCTYPE html>
<html>
 <body>
  <h2>Hello, Azure Bootcamp!</h2>
 </body>
</html>
```

※viを利用しているケースでコピー＆ペーストで文字が欠ける場合は、次の方法で対処できます。

- ペーストモードを使う
  - viの中で、「:set paste」とcommandを入力
  - ※元のモードに戻るには「:set nopaste」
- 1行ずつコピー＆ペーストする
- Windowsの場合、別のターミナルアプリをインストールして利用する
  - 例） RLogin http://nanno.dip.jp/softlib/man/rlogin/

ファイルを保存してからブラウザでアクセスしてください。

- http://_作成したVMのIPアドレス_/hello.html 

上記の例の場合、次のように表示さればOKです。

![helloページ](/images/azure_hello_page.png)

### DNSの利用

AzureのパブリックIPアドレスには、DNS機能があります。こちらも使ってみましょう。

- ポータルで、作成したVMの概要を表示
  - 「パブリック IP アドレス」の値をクリック
- 今回作成されたパブリックIPアドレス（この例では firstVM-ip ）の概要が表示される
  - 左のメニューで「構成」をクリック
  - 「DNS 名ラベル (オプション)」に名前を指定
    - 英小文字、数字、ハイフンのみ（大文字は利用できない）
    - この地域で一意になる名前が必要（他の人のぶつからないように）
  - 上部の「保存」メニューをクリック

![DNS指定](/images/azure_dns_name.png)

- ブラウザで指定したDNS名を使ったURLにアクセス
  - http://_firstvm77_.japaneast.cloudapp.azure.com/hello.html (※今回の例)


## 後片付け

今回VMを作成しましたが、関連して複数のリソースが作成されています。Azureのポータル画面で今回作成したリソースグループ（例では myVMgroup）を見てみると、次のようなリソースが存在していることが分かります。

- 仮想マシン
- OS用ディスク
- ネットワークインターフェイス
- 仮想ネットワーク
- パブリックIPアドレス
- ネットワークセキュリティグループ
- SSHキー

![リソース類](/images/azure_resource_block.png)

一つ一つ削除しても良いですが、リソースグループごと削除することで、いっぺんに片付けることができます。

- リソースグループ（例では myVMgroup)を表示
- 「リソースグループの削除」メニューをクリック
- 「"myVMgroup" を削除しますか?」の確認画面が表示
  - 「選択した仮想マシンと仮想マシン スケール セットに対して強制削除を適用する」をチェック？？
  - リソース グループ名を入力
- [削除]ボタンをクリック
- リソースグループとその配下のリソースが削除される
  - 数分かかる

![リソースグループの削除](/images/azure_delete_resoucegroup_confirm.png =300x)

## まとめ/次回予告

Azureを初めて使う人向けに、ポータル画面からの操作を実施しました。次はクラウドならではのコマンドラインからの操作をやってみる予定です。

- 2. [CLIを使って、コマンドでVMを起動する](azure-bootcamp-2-vm-by-cli)

## シリーズの記事一覧

- 0. [このシリーズについて](azure-bootcamp-0-about)
- 1. [Azure Portalを使って、ブラウザからVMを起動する](azure-bootcamp-1-vm-by-portal)
- 2. [CLIを使って、コマンドでVMを起動する](azure-bootcamp-2-vm-by-cli)
- 3. ロードバランサー（Application Gateway)を使って、その裏でVMを入れ替える
  - 簡易的な Blue-Green デプロイを行う

