---
title: "WebRTC (旧)Insertable Streams と ScriptTransform の相互通信実験" # 記事のタイトル
emoji: "📷" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["webrtc"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---

# WebRTC Insertable Stream とは

WebRTCで映像や音声のエンコード済みのデータを取得、加工できる仕組み。エンコード後、パケット分割前のデータを操作することができるため、主にEnd-to-End Encryptionの用途で使われる。

非標準の(旧)Insertabe Streamと、現在標準化プロセスに乗っている(現)Insertable Streamである「WebRTC Encoded Transform」がある。

- 参考： webrtcHacks [True End-to-End Encryption with WebRTC Insertable Streams](https://webrtchacks.com/true-end-to-end-encryption-with-webrtc-insertable-streams/) 


# (旧)Insertable Stream のおさらい

Chromeでサポートされている。

- 2023年9月現在この仕様は標準化のプロセスから外れていて、Chrome独自機能として残っている
  - 仕様のドラフトや、Explainerは残っていない
  - W3C WebRTC WG Meeting の資料が残っている
    - https://www.w3.org/2011/04/webrtc/wiki/images/8/86/WebRTCWG-2020-02-27.pdf P.29〜

## 使い方

(1) RTCPeerConnection のインスタンスを作る際に、オプションを指定

```js
let peer = new RTCPeerConnection({ encodedInsertableStreams: true });
```

(2) 送信側の対応

- RTCRtpSender.createEncodedStreams() で ReadableStream と WritableStreamを取り出す
- 変換処理を挟み込む

```js
function setupSenderTransform(sender) {
  const senderStreams = sender.createEncodedStreams();
  const readableStream = senderStreams.readable;
  const writableStream = senderStreams.writable;

  const transformStream = new TransformStream({
    transform: encodeFunction, // 用意した変換関数を指定
  });

  // 変換を挟んで、readableStreamとwritableStreamを接続
  readableStream
    .pipeThrough(transformStream)
    .pipeTo(writableStream);
}

// RTCRtpSenderを取得し、変換関数をセットアップする
peer.getSenders().forEach(setupSenderTransform);
```

(3) 受信側の指定

- RTCRtpReceiver.createEncodedStreams() で ReadableStream と WritableStreamを取り出す
- 変換処理を挟み込む

```js
function setupReceiverTransform(receiver) {
  const receiverStreams = receiver.createEncodedStreams();
  const readableStream = receiverStreams.readable;
  const writableStream = receiverStreams.writable;

  const transformStream = new TransformStream({
    transform: decodeFunction, // 用意した逆変換関数を指定
  });

  // 逆変換を挟んで、readableStreamとwritableStreamを接続
  readableStream
    .pipeThrough(transformStream)
    .pipeTo(writableStream);
}

// RTCPeerConnection.ontrack()イベント等でRTCRtpReceiverを取得し、変換関数をセットアップする
peer.ontrack = function (evt) {
  setupReceiverTransform(evt.receiver);
}
```

## Workerの利用

- 変換処理をメインスレッドで行うことも可能
- 変換処理をWorkerスレッドで行うことも可能
  - 重い処理の場合は、Workerスレッドで行うことが推奨
  - メインスレッドで readableStream, writableStreamを取得し、workerスレッドに渡して利用する

## GitHub Pagesで試す

- Chrome m86以上で、https://mganeko.github.io/webrtc_insertable_demo/insertable_stream.html にアクセス
- [Start Video]ボタンをクリックし、カメラから映像を取得
  - 左に映像が表示される
  - [use Audio]がチェックされていると、マイクの音声も取得
- [Connect]ボタンをクリック
  - ブラウザの単一タブ内で2つのPeerConnectionの通信が確立
  - 右に受信した映像が表示される
- ストリームデータの加工
  - 左の[XOR Sender data]をチェックすると、送信側でストリームのデータを加工
  - 右の[XOR Receiver data]をチェックすると、受信側でストリームのデータを逆加工
  - どちらも加工しない、あるいは加工する場合のみ、正常に右の映像が表示できる
  - ※映像の乱れや回復が反映されるまで、時間がかかることがあります

**Chromeの例**

![demo画像](https://mganeko.github.io/webrtc_insertable_demo/img/insertable_streams_demo.gif)

## 参考

- [True End-to-End Encryption with WebRTC Insertable Streams](https://webrtchacks.com/true-end-to-end-encryption-with-webrtc-insertable-streams/)
- [WebRTC Insertable Streams で映像ストリームをいじってみた](https://qiita.com/massie_g/items/2b0b6d4f61f1865b4da5)


# ScriptTransform とは

2023年9月現在、WebRTCの仕様の標準化検討中の仕様で、Safari 15.4〜、Firefox 117〜 でサポート。

- Explainer - WebRTC Insertable Streams
  - https://github.com/w3c/webrtc-encoded-transform/blob/main/explainer.md
- 仕様のドラフト: WebRTC Encoded Transform
  - https://w3c.github.io/webrtc-encoded-transform/

旧Insertable Streamとは異なり、Workerの利用が前提となっている。

## 使い方

(1) RTCPeerConnection のインスタンスを作る際に、オプションを指定

```js
let peer = new RTCPeerConnection({ encodedInsertableStreams: true });
```

(2) 送信側の対応

- 変換処理を行う、workerを用意する
- RTCRtpScriptTransformのインスタンスを生成し、RTCRtpSenderに設定する

```js
// --- workerを読み込む ---
const worker = new Worker('ワーカーのjsファイル名', {name: '適切な名前'});

function setupSenderTransform(sender) {
  sender.transform = new RTCRtpScriptTransform(worker, {operation: 'encode'}); // workerのイベントを呼び出す
  return;
}

// RTCRtpSenderを取得し、変換関数をセットアップする
peer.getSenders().forEach(setupSenderTransform);
```

workerの例
```js
// ScriptTransform利用時のイベント
onrtctransform = (event) => {
  const transformer = event.transformer;
  const readable = transformer.readable;
  const writable = transformer.writable;

  if (transformer.options.operation === "encode") {
    const transformStream = new TransformStream({
      transform: encodeFunction,  // 用意した変換関数を指定
    });

    // 変換を挟んで、readableStreamとwritableStreamを接続
    readable
      .pipeThrough(transformStream)
      .pipeTo(writable);
  }
  else if (transformer.options.operation === "decode") {
    const transformStream = new TransformStream({
      transform: decodeFunction,  // 用意した逆変換関数を指定
    });

    // 逆変換を挟んで、readableStreamとwritableStreamを接続
    readable
      .pipeThrough(transformStream)
      .pipeTo(writable);
  }
}
```

(3) 受信側の指定

- 変換処理を行う、workerを用意する
- RTCRtpScriptTransformのインスタンスを生成し、RTCRtpReceiverに設定する

```js
// --- workerを読み込む ---
const worker = new Worker('ワーカーのjsファイル名', {name: '適切な名前'});

function setupReceiverTransform(sender) {
  sender.transform = new RTCRtpScriptTransform(worker, {operation: 'decode'}); // workerのイベントを呼び出す
  return;
}

// RTCPeerConnection.ontrack()イベント等でRTCRtpReceiverを取得し、変換関数をセットアップする
peer.ontrack = function (evt) {
  setupReceiverTransform(evt.receiver);
}
```

## GitHub Pagesで試す

- Safari 16.xか、Firefox117以上で https://mganeko.github.io/webrtc_insertable_demo/script_transform.html にアクセス
- [Start Video]ボタンをクリックし、カメラから映像を取得
  - 左に映像が表示される
  - [use Audio]がチェックされていると、マイクの音声も取得
- [Connect]ボタンをクリック
  - ブラウザの単一タブ内で2つのPeerConnectionの通信が確立
  - 右に受信した映像が表示される
- ストリームデータの加工
  - 左の[XOR Sender data]をチェックすると、送信側でストリームのデータを加工
  - 右の[XOR Receiver data]をチェックすると、受信側でストリームのデータを逆加工
  - どちらも加工しない、あるいは加工する場合のみ、正常に右の映像が表示できる
  - ※映像の乱れや回復が反映されるまで、時間がかかることがあります

**Safariの例**

![demo画像2](https://mganeko.github.io/webrtc_insertable_demo/img/script_transform_demo.gif)

# 相互通信のテスト

新旧Insertable StreamはAPIは違うものの、やっていることは同等なので、通信の互換性はあるはず。そこで相互通信のテストを実施。

## 概要

- 通信方式 ... P2P
- シグナリング ... [Ayame-Labo](https://ayame-labo.shiguredo.app)を利用
- sender ... 送信側。カメラ映像を取得して送信
- receiver ... 受信側。映像を受信して送信
- 簡易暗号化 ... データをXORでビット反転
  - チェックボックスで、ビット反転をon/offする
  - sender/receiverの双方がon、または双方がoffの場合に正常に通信できる

## GitHub Pagesで試す

ScriptTransformがサポートされている場合はそちらを利用（Safari/Firefoxの場合）、createEncodedStreams（旧Insertable Stream）がサポートされている場合はそれを利用する（Chromeの場合）。

- 送信側 [sender](https://mganeko.github.io/webrtc_insertable_demo/sender.html) をブラウザで開く
  - RoomID を指定
  - [Start Video]ボタンをクリックし、カメラから映像を取得
映像が表示される
    - [use Audio]がチェックされていると、マイクの音声も取得
  - [Connect]ボタンをクリック
    - Ayame-Laboに接続、シグナリング待ち
- 受信側 [receiver](https://mganeko.github.io/webrtc_insertable_demo/receiver.html)
  - RoomID を指定
  - [Connect]ボタンをクリック
    - Ayame-Laboに接続、シグナリング開始
  - P2P通信が確立し、受信した映像が表示される
- ストリームデータの加工
  - 送信側の[Sender XOR Simple Encryption]をチェックすると、送信側でストリームのデータを加工
  - 受信側の[Receiver XOR Simple Decryption]をチェックすると、受信側でストリームのデータを逆加工
  - どちらも加工しない、あるいは加工する場合のみ、正常に受信映像が表示できる

**Sender:Safari → Reciever:Chrome の例**

![demo画像3](https://mganeko.github.io/webrtc_insertable_demo/img/sender-receiver_trim.gif)

## GitHub でコードを見る

リポジトリ [mganeko/webrtc_insertable_demo](https://github.com/mganeko/webrtc_insertable_demo)

- [sender.html](https://github.com/mganeko/webrtc_insertable_demo/blob/master/sender.html)
- [receiver.html](https://github.com/mganeko/webrtc_insertable_demo/blob/master/receiver.html)
- [worker.js](https://github.com/mganeko/webrtc_insertable_demo/blob/master/js/worker.js)


# 参考

- E2EE Example
  - Page https://webrtc.github.io/samples/src/content/insertable-streams/endtoend-encryption/
  - Code https://github.com/webrtc/samples/tree/gh-pages/src/content/insertable-streams/endtoend-encryption

- 経緯
  - https://groups.google.com/a/mozilla.org/g/dev-platform/c/Gowr5Fx5jng



