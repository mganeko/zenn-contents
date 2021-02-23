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

## MediaStreamTrackProcessorの生成

MediaStreamからAudioのMediaStreamTrackを取得し、それを引数にMediaStreamTrackProcessorのインスタンスを生成します。

```js
  const [audioTrack] = mediastream.getAudioTracks();
  const processor = new MediaStreamTrackProcessor(audioTrack);
```

## WebAudioで再生する場合

まずWritableStreamを作成し、そのwrite()ハンドラでAudioFrameを取得します。
AudioFrameからはAudioBufferを取得し、それをWebAudioのAudioBufferSourceNodeを使って再生します。

```js
  // --- WebAudio AudioContextの準備 ---
  const audioCtx = new AudioContext();
  const audioSampleRate = audioCtx.sampleRate;
  let audioTime = audioCtx.currentTime;

  // --- WritableStreamを準備 ---
  const writable = new WritableStream({
    // --- AudioFrameが渡された時のイベント ---
    write(audioFrame) {
      // --- WebAudioを使って再生する ---
      const source = audioCtx.createBufferSource();
      source.buffer = audioFrame.buffer;
      source.connect(audioCtx.destination);
      source.start(audioTime);
      audioTime = audioTime + audioFrame.buffer.duration;
    },

    // --- その他のイベント ---
    start() {
      console.log('Audio Writable start');
    },
    close() {
      console.log('Audio Writable close');
    },
    abort(reason) {
      console.log('Audio Writable abort:', reason);
    },
  });

  // --- にMediaStreamTrackProcessor のストリームを接続する ---
  processor.readable.pipeTo(writable);
```

## MediaStreamTrackGeneratorで書き出す

## WebCodecsでエンコードする




# 参考

- [WebRTC Insertable Media using Streams](https://w3c.github.io/webrtc-insertable-streams/)
- [MediaStreamTrack Insertable Media Processing using Streams](https://w3c.github.io/mediacapture-insertable-streams/)

https://webrtc.github.io/samples/
