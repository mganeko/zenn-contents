---
title: "requestAnimationFrameの泣き所をVideoTrackReaderで解決する" # 記事のタイトル
emoji: "🎬" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["JavaScript", "WebCodec", "WebRTC" ] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

ブラウザのリアルタイム通信の仕組みとしてWebRTCがありますが、より細かい制御を行うことができるWebCodecsやWebTransportといった仕様が提案されれています。今回はその中でもWebCodecsの関連であるVideoTrackReader/VideoFrameを映像合成/映像加工に使う例を取りあげます。

# 映像加工のこれまで

VideoElemet --> CanvasのContext.drawImage(video, x, y) --> captureStream

これを定期的に繰り返すことで動画になります。

定期的にdrawImageを行うには、次の2つの方法がありますが、それには弱点があります。

- window.requestAnimationFrame()
  - ブラウザに余力があれば、高頻度で描画処理を呼び出す（多くのケースで60FPS）
  - ブラウザのウィンドウ/タブが完全に隠れたり最小化されると、呼び出しの間隔が開くか、全く呼び出され無い。結果として動画が停止してまう
- window.setInterval()
  - 呼び出しの間隔が不揃いになることがある
  - ブラウザのウィンドウ/タブが完全に隠れたり最小化されると、呼び出しの間隔が極端に遅くなることある。結果として動画がコマ送りのような状態になる

# VideoTrackReaderを使った場合




これは画面をそのまま見る/見せる場合には問題になりませんが、次のようにさらに別の用途で利用する場合には問題になるケースがあります。


# 参考

[WebCodecs と WebTransport でビデオチャット](https://blog.jxck.io/entries/2020-09-01/webcodecs-webtransport-chat.html)

[Video processing with WebCodecs](https://web.dev/webcodecs/)

