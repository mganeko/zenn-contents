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

WHIP対応のサーバーを利用する場合、ブラウザでもそのまま接続できるケースもありますが、接続できない場合もあります。OBS対応を歌っているサーバーの場合は、ブラウザでOBSのフリをすることで接続できるケースもあります。（※OBSのフリをして接続することが利用規約に反する場合もあるので、ご注意ください）

### メディアの順を固定

MediaStream から MediaStreamTrackを取得し、PeerConnectionに追加(addTrack)する際に、その順番を固定することでSDPに出現するメディアの順番をコントロールすることができる。

コードでは次のように明示的に Audioトラックを取得＆追加、その後にVideoトラックを取得＆追加する。

```js
  // -- set auido track --
  mediastream.getAudioTracks().forEach(track => {
    const sender = peer.addTrack(track, mediastream);
  });

  // -- set video track --
  mediastream.getVideoTracks().forEach(track => {
    const sender = peer.addTrack(track, mediastream);
  });
```

audio, video を区別しないで取り出した場合、順不同になることがある。この場合はSDPでのメディアの登場順も順不同になる。

```js
  mediastream.getTracks().forEach(track => {
    const sender = peer.addTrack(track, mediastream);
  });
```

### コーデックを限定

VideoコーデックではH.264のみ、AudioコーデックではOpusのみを利用する。

```js

const tranceivers = peer.getTransceivers();
tranceivers.forEach(transceiver => {
  transceiver.direction = 'sendonly'; // 通信方向を送信専用に設定する
  if (transceiver.sender.track.kind === 'video') {
    setupVideoCodecs(transceiver);
  }
  else if(transceiver.sender.track.kind === 'audio') {
    setupAudioCodecs(transceiver);
  }
})
  
function setupVideoCodecs(transceiver) {
  if (transceiver.sender.track.kind === 'video') {
    const codecs = RTCRtpSender.getCapabilities('video').codecs;
    
    // コーデックをH.264でフィルタし、最初のものだけ残す
    const h264Codecs = codecs.filter(codec => codec.mimeType == "video/H264");
    const h264Codec1 = [];
    h264Codec1.push(h264Codecs[0]); 
    transceiver.setCodecPreferences(h264Codec1);  // NOT supported in Firefox
  }
}

function setupAudioCodecs(transceiver) {
  if (transceiver.sender.track.kind === 'audio') {
    const codecs = RTCRtpSender.getCapabilities('audio').codecs;

    // コーデックをOPUSでフィルタし、最初のものだけ残す
    const opusCodecs = codecs.filter(codec => codec.mimeType == "audio/opus");
    const opusCodecs1 = [];
    opusCodecs1.push(opusCodecs[0]);
    transceiver.setCodecPreferences(opusCodecs1);
  }
}
```

### ヘッダー指定

これはOBSのフリとは無関係に、WHIPの仕様に従います。

(1) 認証が必要な場合は、リクエストヘッダーでAuthenticationを指定

```js
  // --- ヘッダー指定例 --
  const token = getAuthToken(); // トークンを取得する処理を用意
  const headers = new Headers();
  headers.set("Content-Type", "application/sdp");
  headers.set("Authorization", 'Bearer ' + token); // トークンを指定
```

(2) 切断処理に備えて、レスポンスヘッダーから、Location情報を取得

```js
  // fetch() の応答のヘッダーからLocationを取得する
  let whipResource = res.headers.get("Location");
```

### CORS回避


## 参考

 - 好奇心旺盛な人のためのWebRTC
  - https://webrtcforthecurious.com/ja/
  - [シグナリング](https://webrtcforthecurious.com/ja/docs/02-signaling/)