---
title: "MediaStreamTrackProcessorでAudioを扱う" # 記事のタイトル
emoji: "🎤" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["JavaScript", "WebCodec", "WebRTC" ] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

ブラウザのリアルタイム通信の仕組みとしてWebRTCがありますが、より細かい制御を行うことができるInsertable StreamやWebCodecsといった仕様が提案されれています。今回はその関連仕様であるMediaStreamTrackProcessorを使って、オーディオを扱う例を取りあげます。

# MediaStreamTrackProcessorとは

MediaStreamTrackProcessorはMediaStreamから取り出したVideo/AudioのMediaStreamTrackを扱うための新しい仕組みです。2021年2月現在、まだW3Cでも非公式なドラフトとして提案されている状態です。

- Unofficial Draft: [MediaStreamTrack Insertable Media Processing using Streams](https://w3c.github.io/mediacapture-insertable-streams/)

MediaStreamTrackProcessorを使うと、VideoのMediaStreamTrackからはViderFrameを、AudioのMediaStreamTrackからはAudioFrameをストリーム（ReadableStream）経由で取り出すことができます。

# MediaStreamTrackProcessorでAudioを扱う方法


## WebAudioで再生する

## MediaStreamTrackGeneratorで書き出す

## WebCodecsでエンコードする




# 参考

- [WebRTC Insertable Media using Streams](https://w3c.github.io/webrtc-insertable-streams/)
- [MediaStreamTrack Insertable Media Processing using Streams](https://w3c.github.io/mediacapture-insertable-streams/)

https://webrtc.github.io/samples/
