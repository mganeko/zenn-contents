---
title: "スマホのカメラに映る景色を音声で案内する Visual Sonar の試作" # 記事のタイトル
emoji: "📷" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["GPT4-V"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---


# メモ

## 全体構成

- getUserMedia() を使って、カメラの映像を取得
- Video要素、Canvas要素を使って、画像を取得
- GPT-4 vision を使って、画像の内容を解析
- Viode API を使って、text-to-speech で読み上げ
- Audio要素で再生

# Visual Sonar とは

Visual Sonarとは、スマホのカメラに映る映像を解析し、音声で教えてくれるWebアプリです。
OpenAIのGTP-4で画像を扱えるようになったので、それを使って作ってみました。

# 構成要素

- mediaDevices.getUserMedia()を使って、カメラの映像取得
- Cnavasを使って、映像から1コマ画像を取得
- OpenAIのgpt-4-vision-previewを使い、画像の内容を解析
- OpenAIのTTS(text-to-speech)を使い、テキストを音声に
- Audio要素で再生

# 各部の実装（抜粋）

説明のために一部抜粋して簡略化しています。

## カメラ映像の取得

背面カメラを使用するため、videoのオプションとして、次のように指定します
- video: { facingMode: "environment" }

```js
async function startCamera() {
  const constraints = {
    video: {
      //facingMode: "user" // フロントカメラを使用
      facingMode: "environment" // 背面カメラを使用
    }
  };

  // カメラの映像を取得
  const stream = await navigator.mediaDevices.getUserMedia(constraints);

  // <video> 要素にストリームを設定
  localVideo.srcObject = stream;
  await localVideo.play();
}
```

## 映像から画像をBase64で取得

Canvas要素を使い、Video要素から1コマ画像を取得します。

```js
  // video ... 映像が表示されているVideo要素
  // canvas ... 作業に使うCanvas要素
  // ctx ... canvasの描画に使うcontext
  function getBase64Image(video, canvas, ctx) {
    // Draw Image
    ctx.drawImage(video, 0, 0);

    // To Base64
    return canvas.toDataURL("image/jpeg");
  }
```