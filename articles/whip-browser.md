---
title: "ブラウザーからWebRTC-HTTP ingestion protocol (WHIP) で接続してみる" # 記事のタイトル
emoji: "📷" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["webrtc"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---


# WebRTCのシグナリング

WebRTCでは、接続に必要な情報を交換する過程をシグナリングと呼びます。

- 交換する情報
  - SDP (Session Description Protocol) ... メディアの種類、利用可能なコーデック、通信方向、などなど
  - ICE candidate ... 通信経路の候補の情報
- 交換方法/手段
  - 規定せず。システム構築者が自由に実装可能

交換方法が規定されていないことは必要に応じてシンプルな手段が利用できる反面、異なるシステム間での相互接続を難しくしています。

# WebRTC-HTTP ingestion protocol (WHIP) とは

WebRTCのシグナリングが元々P2Pでの利用を想定しているため、WebSocketのような双方向のリアルタイム通信の仕組みが利用されることが多いです。一方で利用シナリオを特定のケースに絞れば、もっとシンプルな手段が取れます。そこで映像の配信（Ingestion: サーバーへのメディアストリームの打ち上げ）に絞って、よりシンプルなシグナリング方法を仕様として規定しているのがWHIPになります。

WHIPの前提
- P2Pではなく、サーバー経由の配信を行う
- WHIPサーバー(WHIPエンドポイント)はグローバルなIPアドレスを持ち、配信クライアントから直接アクセスできる
- 配信に特化しているため、映像/音声は配信クライアント→サーバの片方向のみ
- 配信デバイスや、配信用ソフトウェアから使うことを想定
- 最少1回のHTTP POSTリクエストの往復で、必要な情報を交換できるシンプルな設計
- Bearer Tokenを使った認証あり

2023年10月現在のドラフト
- [WebRTC-HTTP ingestion protocol (WHIP)](https://www.ietf.org/archive/id/draft-ietf-wish-whip-09.html)

## WHIP接続の流れ

- WHIPクライアントは、Offer SDPを生成してPOSTのボディとしてサーバー送信
  - Content-Typeとして"application/sdp"を指定
  - 認証する場合は、 AuthorizationヘッダーでBearer Tokenを指定する
- WHIPサーバーはAnswer SDPをレスポンスのボディで返す
  - ステータスコードは201(Created)を返す
  - Content-Typeは"application/sdp"
  - LocationヘッダーでWHIPリソースのURLを返す

- WHIPを切断する時は、WHIPリソースのURLに対してWHIPクライアントからDELETEリクエストを送る

# WHIP対応のサービス

WHIP対応のサービスには、次のようなものがあります。

- Cloudflare Stream
  - [WebRTC Beta](https://developers.cloudflare.com/stream/webrtc-beta/)
- 時雨堂 Sora
  - [Sora Labo](https://sora-labo.shiguredo.app/)
    - [OBSのWHIPに限定して対応](https://github.com/shiguredo/sora-labo-doc#obs-webrtc-%E5%AF%BE%E5%BF%9C)

それぞれに対して、ブラウザからWHIP接続を試してみました。

## Cloudflare StreamへのWHIP接続

Cloudflare StreamへのWHIP接続では、次の制限があります。

- WHIP接続による映像は、同じくWebRTC経由で視聴するためのWHEP接続とセットで利用することが前提
  - WHIP接続 → HLS配信 はまだサポートされない
- WHIP接続による映像は、CloudflareのダッシュボードやHLS配信視聴ページでは見ることができない
  - ※これに気が付かず、WHIP接続がうまく動作しないと無駄に悩んでしまった

### WHIP接続の手順

- Cloudflare StreamのLive Inputを作成
  - 今回はダッシュボードから作成
  - webRTC - url の値がWHIPのエンドポイント（POST先）
    - "https://xxxxxxx.cloudflarestream.com/xxxxxxxxxx/webRTC/publish" の形式
- ブラウザからOfferを送る
  - RTCPeerConnectionのオブジェクトを生成
    - 映像トラック、音声トラックを追加
    - Transceiverをsendonlyに設定
  - Offer SDPを生成
  - 上記で生成したエンドポイントに対して、Offer SDPをPOST
    - Bearer Tokenによる認証は無し
  - WHIPリソースは相対パスで戻ってくる
    - 切断のDELETEリクエスト送信時は、https://xxxxxxx.cloudflarestream.com/WHIPリソース の形式でURLを組み立ててリクエストを送る必要がある

cloudflare提供のWHIPクライアントのサンプルもありますが、今回は仕組みの確認のため自分でコードを書いて動作を確認しました。

- cloudflare社のサンプル(ブラウザ用)
  - https://github.com/cloudflare/workers-sdk/tree/main/templates/stream/webrtc

```js:SDP送信の例
  // --- sdpを送信する ---
  async function sendWHIP(sdp, endpoint, token) {
    // -- ヘッダーを組み立てる --
    const headers = new Headers();
    const opt = {};
    headers.set("Content-Type", "application/sdp");
    if (token && token.length > 0) {
      headers.set("Authorization", 'Bearer ' + token); // ※Cloudflareではtokenは使わない
    }

    opt.method = 'POST';
    opt.headers = headers;
    opt.body = sdp;
    opt.keepalive = true;

    const res = await fetch(endpoint, opt);
    if (res.status === 201) {
      // --- WHIPリソースを取得し、覚える --
      whipResource = res.headers.get("Location");
      setWhipResouce(whipResource); // 覚える

      // -- answer SDPを返す ---
      const sdp = await res.text();
      return sdp;
    }

    // --- 何らかのエラーが発生 ---
    // ... 省略 ...
  }

```

### WHEPクライアント

WHIPと同様にHTTPリクエストでシグナリングを行う、視聴者側のプロトコルのWebRTC-HTTP egress protocol (WHEP)が規定されています。上記cloudflare社のサンプルにはWHIPクライアントも含まれているので、それを使って自作WHIPクライアントで配信した映像が見られることを確認しました、

- cloudflare社のサンプル WHEPクライアント
  - https://github.com/cloudflare/workers-sdk/blob/main/templates/stream/webrtc/src/whep.html
  - ※利用にあたっては、ダッシュボードでLive Inputを作成した際の「webRTCPlayback」のURLをエンドポイントとして指定する

ちなみにこちらのサンプルコードを読んでいて、WHEPのvideoとaudioは別々のMediaStreamに分かれているケースがあることが分かりました。自作のWHEPクライアントで接続する場合にはその配慮が必要です。


## Sora LaboへのWHIP接続

もう一つWHIPに対応したサービスとして、時雨堂のSora Laboへの接続も試してみました。Sora/Sora LaboはWHIP対応を謳っているのではなく、OBSからのWHIP接続のみサポートしていると明記されています。今回のようにブラウザからの接続は対象外となるので、ご注意ください。

- 事前準備： Sora Laboの利用には、GitHubアカウントによるサインサインアップが必要です
  - ドキュメント： https://github.com/shiguredo/sora-labo-doc
  - ※商用利用、アカデミック利用はできません。あくまで検証用でご利用ください


### クロスオリジン対策

Sora LaboのWHIP接続はOBSからの利用だけを想定しているので、ブラウザから直接POSTする際のクロスオリジンの利用はできません（ブラウザの制約にひっかっかる）。そのため、今回はNode.jsで中継するサーバーを用意しました。
※本来、ブラウザから利用する場合は公式の[sora-js-sdk](https://github.com/shiguredo/sora-js-sdk)を利用し、WebSocket経由のシグナリングを利用します。

通信イメージ
※画像を用意予定

### トラックの順序

試行していて気がついたこととして、映像(video)と音声(audio)のトラックを音声→映像の順に追加する必要があります。OBSではこの順序が固定になっており、Sora Laboでもそれが前提となっているようです。

```js:順序が場合によって異なり、接続できない場合がある
  // mediastream ... 送信するメディア
  // peer ... 通信に使うRTCPeerConnectionのオブジェクト
  mediastream.getTracks().forEach(track => {
    const sender = peer.addTrack(track, mediastream);
  });
```

Offerがvideo→audioの順になっていても、サーバーから返ってくるAswerはaudio→videoの順に固定されている。そのためブラウザ側でAnswerを受け取る際に順番不一致のエラーになる。

```js:明示的にaudio→videoの順に追加すればOK
  // mediastream ... 送信するメディア
  // peer ... 通信に使うRTCPeerConnectionのオブジェクト

  // -- set auido track --
  mediastream.getAudioTracks().forEach(track => {
    const sender = peer.addTrack(track, mediastream);
  });

  // -- set video track --
  mediastream.getVideoTracks().forEach(track => {
    const sender = peer.addTrack(track, mediastream);
  });
```

### コーデックの限定

OBSではWHIPで利用できるコーデックが限定されています。

- videoコーデック ... H.264のみ
- audioコーデック ... Opusのみ

Chrome系/Safariでは次のコードでコーデックを限定できます。

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
    
    // コーデックをH.264でフィルタする
    const h264Codecs = codecs.filter(codec => codec.mimeType == "video/H264");
    transceiver.setCodecPreferences(h264Codecs);  // NOT supported in Firefox
  }
}

function setupAudioCodecs(transceiver) {
  if (transceiver.sender.track.kind === 'audio') {
    const codecs = RTCRtpSender.getCapabilities('audio').codecs;

    // コーデックをOPUSでフィルタする
    const opusCodecs = codecs.filter(codec => codec.mimeType == "audio/opus");
    transceiver.setCodecPreferences(opusCodecs);
  }
}
```

※Sora Laboでの接続で試したところ、コーデックの限定は行わなくても接続できました。


