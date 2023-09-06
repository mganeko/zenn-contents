---
title: "WebRTC (旧)Insertable Streams と ScriptTransform の相互通信実験" # 記事のタイトル
emoji: "📷" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["webrtc"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---


# WebRTC (旧)Insertable Stream のおさらい

Chromeでサポートされている映像や音声のエンコード済み、かつパケット分割前のデータを取得できる仕組みで、主にEnd-to-End Encryptionの用途で使われる。

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

## 参考

- [True End-to-End Encryption with WebRTC Insertable Streams](https://webrtchacks.com/true-end-to-end-encryption-with-webrtc-insertable-streams/)
- [WebRTC Insertable Streams で映像ストリームをいじってみた](https://qiita.com/massie_g/items/2b0b6d4f61f1865b4da5)


# ScriptTransform とは

2023年9月現在、WebRTCの仕様の標準化検討中の仕様で、映像や音声のエンコード済み、かつパケット分割前のデータを取得できる。主にEnd-to-End Encryptionの用途で使われる。

Safari 15.4〜、Firefox 117〜 でサポート。

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

# サンプル

- example
  - Page https://webrtc.github.io/samples/src/content/insertable-streams/endtoend-encryption/
  - Code https://github.com/webrtc/samples/tree/gh-pages/src/content/insertable-streams/endtoend-encryption


- 経緯
  - https://groups.google.com/a/mozilla.org/g/dev-platform/c/Gowr5Fx5jng


