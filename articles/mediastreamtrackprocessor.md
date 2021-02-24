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

## 準備： MediaStreamTrackProcessorの生成

MediaStreamからAudioのMediaStreamTrackを取得し、それを引数にMediaStreamTrackProcessorのインスタンスを生成します。

```js
  const [audioTrack] = mediastream.getAudioTracks();
  const processor = new MediaStreamTrackProcessor(audioTrack);
```

## WebAudioで再生する場合

まずWritableStreamを作成し、そのwrite()ハンドラでAudioFrameを取得します。
AudioFrameからAudioBufferを取得し、それをWebAudioのAudioBufferSourceNodeを使って再生します。
MediaStreamTrackProcessorを作成したWritableStreamに接続することで、Audioデータを流し込むことができます。

```js
  // --- WebAudio AudioContextの準備 ---
  const audioCtx = new AudioContext();
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

  // --- WritableStream に MediaStreamTrackProcessor のストリームを接続する ---
  processor.readable.pipeTo(writable);
```

## MediaStreamTrackGeneratorを使う場合

MediaStreamTrackProcessorを使うとMediaStreamTrackからAudioFrameを取り出すことができますが、MediaStreamTrackGeneratorを使うことで反対にAudioFrameをMediaStreamTrackを作り出すことができます。

```js
  // --- Generatorを用意 ---
  const generator = new MediaStreamTrackGenerator('audio');

  // --- MediaStreamTrackProcessor のストリームと接続する
  processor.readable.pipeTo(generator.writable);

  // --- MediaStreamに追加し、AudioElementで再生する --
  const generatedStream = new MediaStream();
  generatedStream.addTrack(generator);
  audioElement.srcObject = generatedStream;
  await audioElement.play();
```

そのまま戻しても意味がないため、通常は途中にTransformStreamを挟んでオーディオデータを加工します。

```js
  // --- TransformStreamを準備 ---
  const transformer = new TransformStream({
    // --- 変換処理 ---
    async transform(audioFrame, controller) {
      // --- AudioFrameからオーディオサンプルを取得 (Float32Array) ---
      const samples = audioFrame.buffer.getChannelData(0); // 1チャンネルと仮定

      // --- 加工を行う ---
      for(let i = 0; i < samples.length; i++) {
        samples[i] = samples[i] + (Math.random() * 2 - 1)*0.1; // ノイズを加える例
      }

      // --- 音オーディオサンプルをAudioFrameに戻す --
      audioFrame.buffer.copyToChannel(samples, 0); // 1チャンネルと仮定

      // --- 次のストリームに渡す ---
      controller.enqueue(audioFrame);
    }
  });

  // MediaStreamTrackProcessor のストリームと
  //   TransformStream、MediaStreamTrackGeneratorを接続する
  processor.readable
    .pipeThrough(transformer)
    .pipeTo(generator.writable);

  // --- この後再生する ---
```


## WebCodecsでエンコード/デコードする場合

MediaStreamTrackProcessorで取り出したAudioFrameは、WebCodecsのAudioEncoderを使ってエンコード（圧縮）することが可能です。これを何かの方法（たとえばWebSocketやWebTrasport）でリモートに送り、AudioDecoderでデコード（復元）すれば音声として再生するここができます。

```js
  // --- Encoderを準備 ---
  const audioEncoder = new AudioEncoder({
    output: function (chunk) {
      // --- エンコード後のデータを受け取る。ここでリモートに送ったりする ---
      // ... 省略 ...
    },
    error: function () {
      console.error(arguments)
    }
  });

  // ---  設定 ---
  const audioCtx = new AudioContext();
  const audioSampleRate = audioCtx.sampleRate;
  await audioEncoder.configure({
    codec: 'opus',
    sampleRate: audioSampleRate,
    bitrate: '128000',
    numberOfChannels: 1,
  });

  // --- WritableStreamを準備 ---
  const writable = new WritableStream({
    // --- AudioFrameが渡された時のイベント ---
    write(audioFrame) {
      // --- エンコードする ---
      audioEncoder.encode(audioFrame);
      audioFrame.close();
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

  // --- WritableStream に MediaStreamTrackProcessor のストリームを接続する ---
  processor.readable.pipeTo(writable);
```

デコード側では、エンコードデータを受け取り、それをデコード（復元）後に再生する。たとえばWebAudioを使って再生する場合は次のようになる。

```js



```

# まとめ

# 参考


- [MediaStreamTrack Insertable Media Processing using Streams](https://w3c.github.io/mediacapture-insertable-streams/)

https://webrtc.github.io/samples/

- [WebCodecs](https://wicg.github.io/web-codecs/)


- [WebRTC Insertable Media using Streams](https://w3c.github.io/webrtc-insertable-streams/)
