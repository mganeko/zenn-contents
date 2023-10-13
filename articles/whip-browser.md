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
  async function sendWHIP(sdp) {
    const endpoint = getWhipEndpoint(); // エンドポイントを取得する
    const token = getAuthToken(); // Bearer Tokenを取得する

    // -- ヘッダーを組み立てる --
    const headers = new Headers();
    const opt = {};
    headers.set("Content-Type", "application/sdp");
    if (token && token.length > 0) {
      headers.set("Authorization", 'Bearer ' + token); // Cloudflareではtokenは使わない
    }

    opt.method = 'POST';
    opt.headers = headers;
    opt.body = sdp;
    opt.keepalive = true;

    const res = await fetch(endpoint, opt)
    if (res.status === 201) {
      // --- WHIPリソースを取得し、覚える --
      whipResource = res.headers.get("Location");
      setWhipResouce(whipResource);

      // -- answerを返す ---
      let sdp = await res.text();
      let answer = new RTCSessionDescription({ type: "answer", sdp: sdp });
      return answer;
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

