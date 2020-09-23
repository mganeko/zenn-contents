---
title: "momo を homebridge から起動する" # 記事のタイトル
emoji: "🍑" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: [webrtc homebridge] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# WebRTC Native Client MomoをHomebridgeから起動する

## やりたいこと

iPhoneに「Hey Siri, 家の様子を見せて」と呼びかけると、Safariで家の様子（ペットや、子供の様子など）見れるようにしよう、というのが今回の狙いです。


## WebRTC Native Client Momoとは

WebRTC Native Client Momoとは、時雨堂が公開している、WebRTCを使ったネイティブクライアントアプリです。

- サイト https://momo.shiguredo.jp/
- GitHub https://github.com/shiguredo/momo

Webブラウザで利用することが多いWebRTCを、ネイティブアプリとして利用できるようにしたオープンソースソフトウェアです。
映像、音声の送信だけでなく、受信にも対応しています。単独で使ったり、同じく時雨堂が提供しているサーバーと連携して利用できます。

複数のプラットフォームをサポートしていますが、Raspberry PiやJetsonシリーズなど、小さなコンピューターの性能を使い切ってくれるところが非常に魅力的です。



## Homebridgeとは

Appleのスマートホーム向けの仕組みであるHomeKitに、対応デバイス以外をつなぐことができるソフトウェアです。npmで対応するプラグインを探すことができます。

- サイト https://homebridge.io/
- GitHub https://github.com/homebridge/homebridge
- 対応プラグイン https://www.npmjs.com/search?q=keywords:homebridge-plugin

こちらも色々なプラットフォームで動作しますが、スマートホームと言ったらRaspberry Piで動かしたくなります。

## HomeKitを使うには

HomeKitはAppleのサービスなので、インターネット経由でも利用できます。そのためには、家のネットワークに中心となる「ホームハブ」を設置する必要があります。2020年9月現在、「ホームハブ」として利用できるのは次の3つです。

- AppleTV（第3世代以降）
- iPad
- HomePod

AppleTVを持っている人は、それを利用するのがスムーズです。私はiPadで利用してますが、安定して利用するには常時ACアダプターにつないでおく必要があります。


# Raspberry piにmomoをインストール

今回はRaspberry Piにセットアップしました。

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




# Raspberry piにHomebrigeをインストール


