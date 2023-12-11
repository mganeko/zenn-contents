---
title: "スマホのカメラに映る景色を音声で案内する Visual Sonar の試作" # 記事のタイトル
emoji: "📷" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["GPT4-V"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

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

Canvas要素を使い、Video要素から1コマ画像をBase64で取得します。

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

## GPT4-V で解析

gpt-4-vision-preview を使って、画像を解析します。従来のChat APIと同様ですが、conentが単なるテキストでなく、テキストと画像URLのセットになっているのが違いです。

```js
// 画像のURL(またはBase64表記)とチャットメッセージを送信し、応答を返す
async function singleChatWithImage(image_url, text) {
  // 従来のChat APIと同様だが、conentが単なるテキストでなく、テキストと画像URLのセットになる
  const userMessage = {
    role: 'user',
    content: [
      {
        "type": "text",
        "text": text,
      },
      {
        "type": "image_url",
        "image_url": {
          "url": image_url,
        }
      }
    ]
  };


  // -- request --
  const API_KEY = 'sk-xxxxxxx';
  const MODEL = 'gpt-4-vision-preview';
  const API_URL = 'https://api.openai.com/v1/chat/completions';
  const options = { temperature: 0, max_tokens: 1000 };
  const response = await _chatCompletion([messages], API_KEY, MODEL, API_URL, options);
  return response;
}

// chat API を呼び出す
async function _chatCompletion(messages, apiKey, chatModel, url, options) {
  //const apiKey = API_KEY;
  //const CHATAPI_URL = "https://api.openai.com/v1/chat/completions";

  const bodyJson = {
    messages: messages,
    model: chatModel,
    temperature: options.temperature,
    max_tokens: options.max_tokens,
  };
  const body = JSON.stringify(bodyJson);
  const headers = {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    };

  const res = await fetch(url, {
    method: "POST",
    headers: headers,
    body,
  });

  // 応答を解析
  const data = await res.json();
  const choiceIndex = 0;
  const choices = data.choices;
  return choices[choiceIndex].message;
};
```
