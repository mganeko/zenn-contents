---
title: "WHIPとOBSとブラウザー。ブラウザーでOBSのふりをして、WHIPにつないてみる" # 記事のタイトル
emoji: "📷" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["webrtc"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# WebRTC-HTTP ingestion protocol (WHIP) とは

## WebRTCのシグナリング

WebRTCでは、接続に必要な情報を交換する過程をシグナリングと呼びます。WebRTC関連の仕様では、このシグナリングについては次の様に規定されています。

- 交換する情報について
  - SDP (Session Description Protocol) ... メディアの種類、利用可能なコーデック、通信方向、などなど
  - ICE candidate ... 通信経路の候補の情報
- 交換方法/手段
  - 規定せず。システム構築者が自由に実装可能

交換方法が規定されていないことは必要に応じてシンプルな手段が利用できる反面、異なるシステム間での相互接続を難しくしています。

## WHIP

WebRTCのシグナリングが元々P2Pでの利用を想定しているため、WebSocketのような双方向のリアルタイム通信の仕組みが利用されることが多いです。一方で利用シナリオを特定のケースに絞れば、もっとシンプルな手段が取れます。そこで映像の配信（Ingestion: サーバーへのメディアストリームの打ち上げ）に絞って、よりシンプルなシグナリング方法を仕様として規定しているのがWHIPになります。

WHIPの前提
- P2Pではなく、サーバー経由の配信を行う
- WHIPサーバー(WHIPエンドポイント)はグローバルなIPアドレスを持ち、配信クライアントから直接アクセスできる
- 配信に特化しているため、映像/音声は配信クライアント→サーバの片方向のみ
- 配信デバイスや、配信用ソフトウェアから使うことを想定
- 1回のHTTP POSTリクエストの往復で、必要な情報を交換できるシンプルな設計
- Bearer Tokenを使った認証あり

2023年10月現在のドラフト
- [WebRTC-HTTP ingestion protocol (WHIP)](https://www.ietf.org/archive/id/draft-ietf-wish-whip-09.html)


# WHIP対応状況

## WHIP 対応のソフトウェア

- OBS Studio 30.0 (現在はBeta 3)
  - [Beta 3のアセット](https://github.com/obsproject/obs-studio/releases/tag/30.0.0-beta3)からビルド版を取得可能
- GStreamer 1.22 ～
  - [downloadページ](https://gstreamer.freedesktop.org/download/)
- simple-whip-client
  - [GitHub meetecho/simple-whip-client](https://github.com/meetecho/simple-whip-client)


## WHIP対応のサーバー

- Cloudflare Stream
  - [WebRTC Beta](https://developers.cloudflare.com/stream/webrtc-beta/)
- 時雨堂 Sora
  - [Sora Labo](https://sora-labo.shiguredo.app/)
    - [OBSのWHIPに限定して対応](https://github.com/shiguredo/sora-labo-doc#obs-webrtc-%E5%AF%BE%E5%BF%9C)
- simple-whip-server
  - [GitHub meetecho/simple-whip-server ](https://github.com/meetecho/simple-whip-server)


# OBSのWHIP対応

## WHIPのプロトコル対応

- POSTでの配信開始
  - AuthenticationヘッダーでBearer Tokenによる認証対応
  - 応答ヘッダーのLocationからWHIPリソースのURLを取得
- DELETEによる配信終了
  - WHIPリソースのURLに対してDELETEリクエストを発行

## OBSのSDPの特長

- メディアが audio → video の順
- videoのコーデック: H.264のみ
- audioのコーデック: Opusのみ


## ブラウザでOBSの振りをする


### メディアの順を固定

- MediaStream から MediaStreamTrackを取得し、PeerConnectionに追加(addTrack)する際に
  - 明示的に Audioトラックを取得＆追加、その後にVideoトラックを取得＆追加する
    - peer.addTrack(mediastream.getAudioTracks()[0]);
    - peer.addTrack(mediastream.getVideoTracks()[0]);
  - トラックを順不同に取り出すと、逆順になることがある
    - mediastream.getTracks().forEach(track => peer.addTrack(track))


### コーデックを限定

### ヘッダー指定

- リクエストヘッダーでAuthenticationを指定
- レスポンスヘッダーから、Location情報を取得

### CORS回避


## 参考

 - 好奇心旺盛な人のためのWebRTC
  - https://webrtcforthecurious.com/ja/
  - [シグナリング](https://webrtcforthecurious.com/ja/docs/02-signaling/)