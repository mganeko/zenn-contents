---
title: "Hey, Siriでmomoを起動、自宅の様子を見る" # 記事のタイトル
emoji: "🍑" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: [webrtc homebridge] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# WebRTC Native Client MomoをHomebridgeから起動する

## TODO

- DONE: momo 最新版
- DONE: momo 起動コマンドの確認
- SKIP: サンプルをアップデート、sora 最新SDKに
- homebridgeの設定方法を確認
- iOS ショートカット
- Siri で使う


## やりたいこと

iPhoneに「Hey Siri, 家の様子を見せて」と呼びかけると、Safariで家の様子（ペットや、子供の様子など）見れるようにしよう、というのが今回の狙いです。そのために次のアプリやサービスを利用します。

- Raspberry Pi （Zero, 3, 4 など）
- WebRTC Native Cleint Momo
- Sora Labo
- HomeKit
- Homebrige

## WebRTC Native Client Momoとは

WebRTC Native Client Momoとは、時雨堂が公開している、WebRTCを使ったネイティブクライアントアプリです。

- サイト https://momo.shiguredo.jp/
- GitHub https://github.com/shiguredo/momo

Webブラウザで利用することが多いWebRTCを、ネイティブアプリとして利用できるようにしたオープンソースソフトウェアです。
映像、音声の送信だけでなく、受信にも対応しています。単独で使ったり、同じく時雨堂が提供しているサーバーと連携して利用できます。

複数のプラットフォームをサポートしていますが、Raspberry PiやJetsonシリーズなど、小さなコンピューターの性能を使い切ってくれるところが非常に魅力的です。



## HomeKitを使うには

HomeKitはAppleの提供するスマートホーム用のサービスで、インターネット経由でも利用できます。HomeKitを利用するには、家のネットワークに中心となる「ホームハブ」を設置する必要があります。2020年12月現在、「ホームハブ」として利用できるのは次の3つです。

- AppleTV（第3世代以降）
- iPad
- HomePod / HomePod mini

AppleTVを持っている人は、それを利用するのがスムーズです。私はiPadで利用してますが、安定して利用するには常時ACアダプターにつないでおく必要があります。ホームハブの設定については省略します。公式ページなどを参考にしてください。

- [HomePod、HomePod mini、Apple TV、iPad をホームハブとして設定する](https://support.apple.com/ja-jp/HT207057)


## Homebridgeとは

Appleのスマートホーム向けの仕組みであるHomeKitに、対応デバイス以外をつなぐことができるソフトウェアです。npmで対応するプラグインを探すことができます。

- サイト https://homebridge.io/
- GitHub https://github.com/homebridge/homebridge
- 対応プラグイン https://www.npmjs.com/search?q=keywords:homebridge-plugin

こちらも色々なプラットフォームで動作しますが、スマートホームと言ったらRaspberry Piで動かしたくなります。


# Raspberry piにmomoをインストール

今回はRaspberry Pi 4にセットアップしました。

## ダウンロード

こちらの手順にしたがってモジュールをダウンロード、解凍します。

- https://github.com/shiguredo/momo/blob/develop/doc/SETUP_RASPBERRY_PI.md

また未インストールであれば、libnspr4, libnss3といった関連するライブラリもインストールしてください。


## テストモードでの確認

USBカメラまたはRaspberry Piのカメラモジュールを接続し、こちらの手順にしたがってテストモードで起動します。

- https://github.com/shiguredo/momo/blob/develop/doc/USE_TEST.md

```
./momo --no-audio-device test
```

この時、カレントディレクトリに解凍してできたhtmlフォルダーが必要です。

momoが起動したら、ブラウザーで http://_RaspberryPiのIPアドレス_:8080/html/test.html にアクセスします。[Connect]ボタンをクリックして、カメラの映像が表示されることを確認しましょう。


## Soraモードでの利用

momoの映像配信をインターネット経由で見たいので、サーバー連携させます。連携には次の2種類が選べます。

- Ayameモード ... [WebRTCシグナリングサービスAyame Lite](https://ayame-lite.shiguredo.jp/beta)と連携
  - 使い方はこちら https://github.com/shiguredo/momo/blob/develop/doc/USE_AYAME.md
- Soraモード ... 製品のSoraか、[WebRTC SFU Sora検証サービスのSora Labo](https://sora-labo.shiguredo.jp)と連携
  - 使い方はこちら https://github.com/shiguredo/momo/blob/develop/doc/USE_SORA.md

今回はSora Laboを使わせていただきました。GitHubアカウントでサインインして「シグナリングキー」を取得しておきます。

- Sora Labo ドキュメント　https://github.com/shiguredo/sora-labo-doc

検証目的では無料で利用できますが、条件があるので確認しておきましょう。

- 商用目的での利用できません
- Sora Labo は検証目的以外では利用できません
- 法人や個人事業主での利用は申請が必須です

などなど。
Soraモードでのmomoからの映像配信は次のように行います。

```
./momo --no-audio-device  sora wss://sora-labo.shiguredo.jp/signaling githubのID@ルーム名  --auto  --audio false --video true --video-codec-type H264 --video-bit-rate 800  --role sendonly --metadata '{"signaling_key": "取得したシグナリングキー"}'
```


ブラウザでの受信は、[Sora Laboのダッシュボード](https://sora-labo.shiguredo.jp/dashboard)から、「シングルストリーム受信」のサンプルを開き、ルーム名を指定してビデオコーデック「H264」を選んで接続、映像が受信できることを確認してください。

あるいは、私が用意したこちらのサンプルでも接続できます。

- https://mganeko.github.io/react_ts_recvonly/?room=githubのID@ルーム名&key=取得したシグナリングキー

※長時間の接続はできませんので、momoおよびブラウザは確認が終わったら終了させてください。

## 起動スクリプトの用意

後で利用するため、次の様にシェルスクリプト(sora.sh)を用意しておきます。今回は momo のバイナリを /home/pi/momo/ にインストールした場合を例にしています。自分の環境に合わせて、momoのバイナリをフルパスで指定してください。

```:sora.sh
nohup /home/pi/momo/momo --no-audio-device sora wss://sora-labo.shiguredo.jp/signaling githubのID@ルーム名 --auto --audio false --video true --video-codec-type H264 --video-bit-rate 800 --role sendonly --metadata '{"signaling_key": "取得したシグナリングキー"}' &
```



# Raspberry piにHomebrigeをインストール

こちらの記事を参考に、Raspberry Pi 4にHomebridgeをインストールしました。

- [【Homebridge】NatureRemoをHomeKit対応させる方法](https://chasuke.com/remo_homebridge/)

## Homebridge本体

私の環境では、Node.jsやavahiはインストール済だったので、Homebridgeのインストールから実施します。また今回はグローバルではなく、ユーザー(ここでは pi とします)のホームディレクトリ下にインストールしました。

```
$ cd
$ mkdir homebridge
$ cd homebridge
$ npm install homebridge
```

warningが出ますが、ひとまずインストールはできたようです。

```
$ npx homebridge
```

として起動されることを確認します。

## プラグイン

Homebridgeはいろいろのなプラグインを利用できるのが魅力です。

- [npm search](https://www.npmjs.com/search?q=keywords%3Ahomebridge-plugin&ranking=popularity)

今回はこちらのプラグインを利用します。

- [homebridge-cmdswitch2](https://www.npmjs.com/package/homebridge-cmdswitch2)
  - オン / オフ / 状態取得 をサポートするプラグイン

```
$ npm install homebridge-cmdswitch2
```

## homebridgeの指定

homebridgeをインストールすると、 ~/.homebridge ディレクトリができているはずです。そこに設定ファイルを作成します。

```
$ cd ~/.homebridge/
$ vi config.json
```

config.jsonの内容は次の様になります。 platforms の部分か今回設定する箇所です。

```json:config.json
{
    "bridge": {
        "name": "Homebridge",
        "username": "xx:xx:xx:xx:xx:xx",
        "port": 51826,
        "pin": "xxx-xx-xxx"
    },

    "description": "raspberry4",

    "accessories": [],

    "platforms": [{
      "platform": "cmdSwitch2",
      "name": "MultiSwitch",
      "switches": [{
        "name" : "momo",
        "on_cmd": "/home/pi/momo/sora.sh",
        "off_cmd": "killall momo",
        "state_cmd": "ps h -C momo",
        "polling": true,
        "interval": 5
       }]
    }]
```

- on_cmd ... オンにする際に実行するコマンド
  - 用意したシェルスクリプト(sora.sh)を絶対パスで指定します（パスは環境に合わせて修正してください）
- off_cmd ... オフにする際に実行するコマンド
  - プロセス名前を指定してkillする、簡易的な対応
- state_cmd ... 状態取得のためのコマンド
  - ps でプロセス名を探すことで、簡易的に実現

## 起動の確認

homebridgeをインストールしたディレクトリに移動し、次の様に起動します。

```
$ npx homebridge
```
