---
title: "requestAnimationFrameの泣き所をVideoTrackReader +αで解決する" # 記事のタイトル
emoji: "🎬" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["JavaScript", "WebCodec", "WebRTC" ] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---

# はじめに

ブラウザのリアルタイム通信の仕組みとしてWebRTCがありますが、より細かい制御を行うことができるWebCodecsやWebTransportといった仕様が提案されれています。今回はその関連仕様であるVideoTrackReaderや、さらに新しい仕様であるMediaStreamTrackProcessorを映像合成/映像加工に使う例を取りあげます。

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

どちらの場合には映像加工で使っているウィンドウは本来は表示しておく必要はありませんが、完全に隠れてしまうと映像が停止/コマ落ちしてしまうので一部でも表示しておく必要があります。

利用例としてはgetDisplayMedia()を使って画面キャプチャーを取得し、その映像を加工するケースが考えられます。他のアプリケーションを全画面表示にすると、ブラウザが隠れてしまうのでCanvasで合成した映像は停止してしまいます。



# VideoTrackReaderを使った解決

VideoTrackReaderを使えば、次の処理 (C) が可能です。

- MediaStreamからビデオトラックを取り出す
- ビデオトラックを指定し、VideoTrackReaderを用意する
- ビデオのフレームが到着するたびにイベントが発生し、コールバックが呼ばれる「
- コールバックでビットマップ画像を取得し、Canvasに描画する

ビデオのフレームごとに呼び出されるため、(A)(B)のようなタイマー系の仕組みは必要ありません。そのためウィンドウが完全に隠れていても呼び出され、映像がコマ送り/停止することはありません。

## VideoTrackReaderを使うには

2021年2月現在、VideoTrackReaderはデフォルトでは有効になっていません。Chrome 88以降で、次のどれかの設定が必要です。

- chrome://flags/#enable-experimental-web-platform-features 有効（Enabled）にする
- chromeを起動する際のコマンドライン引数で、--enable-blink-features=WebCodecs を指定して起動する（※未確認）
- オリジントライアルに登録する ... 
https://developer.chrome.com/origintrials/#/view_trial/-7811493553674125311

フラグ設定

![フラグ設定](https://storage.googleapis.com/zenn-user-upload/2wa8rlwb3gwgws74prqx35dxwqn8)

## コード例

```js
  let videoTrackReader = null;

  // --- VideoTrackReader を準備する ---
  function startReader(stream) {
    const track = stream.getVideoTracks()[0];
    videoTrackReader = new VideoTrackReader(track);
    videoTrackReader.start(async (videoFrame) => {
      const imageBitmap = await videoFrame.createImageBitmap();

      // --- この中でCanvasへの描画を行う ---
      drawCanvasBitmap(imageBitmap);
      
      imageBitmap.close();
      videoFrame.destroy();
    });
  }

  // --- VideoTrackReader を停止する ---
  function stopReader() {
    videoTrackReader.stop();
    videoTrackReader = null;
  }
```

# MediaStreamTrackProcessorを使う方法

VideoTrackReaderの検証を行っていうる最中に、Chromeコンソールに次のメッセージが表示されることに気がつきました。

```
[Deprecation] VideoTrackReader is deprecated; use MediaStreamTrackProcessor instead.
```

なんとVideoTrackReaderはもはや非推奨で、新たに「MediaStreamTrackProcessor」を使えとうことです。これはInsertableStreamの一環として提案されているものでした。

- https://w3c.github.io/mediacapture-insertable-streams/

使い方はVideoTrackReaderとは異なりますが、こちらを使った場合 (D) でも画面が完全に隠れた状態で映像が停止することを回避できます。

## コード例

```js
  let processor = null;
  let writable = null;

  // --- MediaStreamTrackProcessor を準備する ---
  function startProcessor(stream) {
    const track = stream.getVideoTracks()[0];
    processor = new MediaStreamTrackProcessor(track);
    writable = new WritableStream({
      start() {
        console.log('Writable start');
      },
      async write(videoFrame) {
        const imageBitmap = await videoFrame.createImageBitmap();

        // --- この中でCanvasへの描画を行う ---
        drawCanvasBitmap(imageBitmap);

        imageBitmap.close();
        videoFrame.destroy();
      },
      stop() {
        console.log('Writable stop');
      }
    })

    processor.readable
      .pipeTo(writable);
  }

  // --- MediaStreamTrackProcessor を停止する ---
  // ※安全な停止方法は不明
  function stopProcessor() {
    //writable.close(); // streamがlockされているため、close()できない
    writable = null;

    //processor.readable.cancel(); // streamがlockされているため、cancel()できない
    processor = null;
  }
```


# サンプル

navigator.mediaDevices.getUserMedia()でカメラ映像を取得し、Canvasで現在時刻を合成、MediaRecorderで録画するサンプルを用意しまました。

- GitHub [mganko/videotrackreader_demo](https://github.com/mganeko/videotrackreader_demo)
- GitHub Pages ... https://mganeko.github.io/videotrackreader_demo/

## 使い方

- Chrome 88以降で「Experimental Web Platform Features」フラグを有効にする
- フラグを有効にしたChromeで https://mganeko.github.io/videotrackreader_demo/ を開く
- 4種類の方法の内、1つをクリックする
- [Start] ボタンをクリック
  - カメラ映像が取得される
  - Canvasにカメラ映像と時刻を合成したアニメーションが表示される
  - 録画が開始
- 録画中に、Chromeのウィンドウを完全に隠したり、最小化してみる
- Chromeのウィンドウを元に戻す
- [Stop] ボタンをクリックkする
  - カメラ映像が停止
  - アニメーション停止
  - 録画停止
  - 録画した映像が再生される

(A)requestAnimationFrame() / (B)setInterval() を使った場合には、録画中にウィンドウが完全に隠れた場合、映像が止まったりコマ送りになっていることが確認できるはずです。
また (C)VideoTrackReader / (D)MediaStreamTrackProcessor を使った場合には、ウィンドウが完全に隠れても、映像がスムーズに動き続けることが確認できます。


# おわりに

Canvasを利用した映像加工では従来の方法では映像が止まってしまう課題がありました。新たに策定が進んでいる VideoTrackReader(ただし非推奨)やMediaStreamTrackProcessorを使うと、その課題が克服できます。フラグが必要になりますが、すでに現在のChromeでは機能を試すことができます。

多くのブラウザでサポートされるようになると、ブラウザを使った映像可能の利用シーンが広がります。楽しみですね。



# 参考

- [WebCodecs と WebTransport でビデオチャット](https://blog.jxck.io/entries/2020-09-01/webcodecs-webtransport-chat.html)
- [Video processing with WebCodecs](https://web.dev/webcodecs/)
- [MediaStreamTrack Insertable Media Processing using Streams](https://w3c.github.io/mediacapture-insertable-streams/)

