---
title: "requestAnimationFrameの泣き所をVideoTrackReaderで解決する" # 記事のタイトル
emoji: "🎬" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["JavaScript", "WebCodec", "WebRTC" ] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

ブラウザのリアルタイム通信の仕組みとしてWebRTCがありますが、より細かい制御を行うことができるWebCodecsやWebTransportといった仕様が提案されれています。今回はその中でもWebCodecsの一部であるVideoTrackReader/VideoFrameを映像合成/映像加工に使う例を取りあげます。

# 映像加工のこれまで

## Canvasを使った映像加工

ブラウザでの映像加工は、従来は次のような流れになります。

- (1) 映像を<video>要素に表示する
- (2) <video>要素から、1コマ分の静止画を<canvas>要素に転写する
  - Canvasからcontextを取得し、context.drawImage()を利用する
- (3) <canvas>要素上で、追加の描画、画像の加工を行う

ここで (2)-(3) を繰り返すことで、<canvas>要素の画像が動画として見えることになります。
さらに次のような処理を追加すると、映像をメディアとして活用できます。

- (4) Canvas.captureStream()で、MediaStreamとして取得する

## 描画の繰り返し方法

### 2種類の繰り返し方法

上記の流れで (2)-(3) の描画を定期的に繰り返す方法として、次の2通りが利用できます。

- (A) window.requestAnimationFrame()
  - ブラウザに余力があれば、高頻度で描画処理を呼び出す（多くのケースで60FPS）
- (B) window.setInterval()
  - 呼び出しの間隔は正確にはコントロールできない。指定より間隔が開くこともある

多くの場面で (A) のrequestAnimationFrameを使うのが適切です。

### 繰り返しの弱点

一般的にはこれはうまく行きますが、次のようなケースでは弱点がありまます。

- ブラウザのウィンドウ/タブが完全に隠れたり最小化されると、呼び出しの間隔が開くか、まったく呼び出されなくなる
- 結果として動画がカクカクしてしまうか、停止してまう

これは画面をそのまま見る/見せるのではなく、下記のように映像メディアを取得して別の場所で使う場合に問題となります。

- MediaStreamをMediaRecorderで録画する
- MediaStreamを、WebRTC (RTCPeerConnection) を使って他のブラウザ/デバイスに対して送信する

これらの場合には映像加工で使っているウィンドウは必ずしも表示しておく必要はありませんが、残念ながら完全に隠れてしまうとうまく動きません。

たとえば、getDisplayMedia()を使って画面キャプチャーを取得し、その映像を加工するケースを考えます。他のアプリケーションを全画面表示にすると、ブラウザが隠れてしまうのでCanvasで合成した映像は停止してしまいます。



# VideoTrackReaderを使った解決

MeidaStream -> MediaStreamTrack (Video) --> VideoTrackReader --> VideoFrame --> createImageBitmap() --> ctx.drawImage(image, x, y)

VideoTrackのフレームごとに呼び出されるため、上記のようなタイマー系の仕組みを必要がない。そのためウィンドウが隠れていても呼び出され、映像がコマ送り/停止することはない。

## VideoTrackReaderを使うには



# サンプル

navigator.mediaDevices.getUserMedia()でカメラ映像を取得し、Canvasで現在時刻を合成、MediaRecorderで録画するサンプルを用意しまました。

## requestAnimationFrame()版

## setInterval()版

## VideoTrackReader版

# おわりに


# 参考

[WebCodecs と WebTransport でビデオチャット](https://blog.jxck.io/entries/2020-09-01/webcodecs-webtransport-chat.html)

[Video processing with WebCodecs](https://web.dev/webcodecs/)

