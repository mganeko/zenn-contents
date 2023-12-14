---
title: "スマホのカメラに映る景色を音声で案内する Visual Sonar の試作" # 記事のタイトル
emoji: "📷" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["GPT4-V"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

これは非公式[Infocom Advent Calendar 2023](https://qiita.com/advent-calendar/2023/infocom)の22日目の記事です。

# Visual Sonar とは

Visual Sonarとは、スマホのカメラに映る映像を解析し、音声で教えてくれるWebアプリです。
OpenAIのGTP-4で画像を扱えるようになったので、それを使って作ってみました。

# 構成要素

- mediaDevices.getUserMedia()を使って、カメラの映像取得
- Cnavasを使って、映像から1コマ画像を取得
- OpenAIのgpt-4-vision-previewを使い、画像の内容を解析
- OpenAIのTTS(text-to-speech)を使い、テキストを音声に
- Audio要素で再生

# 動作している様子

iPhoneで動いている様子を、画面録画しました。最後の方で音が出ます（テキストを読み上げています）

- [vsonar_snow.mp4](https://mganeko.github.io/visual_sonar/video/vsonar_snow.mp4)


# 使い方

GitHub Pagesで試すことができます

## URL

- [GitHub Pages vsonar](https://mganeko.github.io/visual_sonar/vsonar.html)

## 使い方

- [vsonar.html](https://mganeko.github.io/visual_sonar/vsonar.html)をブラウザで表示
- [api key]に、OpenAIのAPIキーを指定
  - または、vsonar.html?key=xxxxxx とURLのクエリーパラメータに指定してもOK
- [Start]ボタンをクリック
  - カメラの許可を求められらた、許可する
  - カメラの映像が表示される
- [Explain in Voice]ボタンをクリック
  - 映像から画面を切り抜き
  - OpenAIの GPT-4 Vで画面を解析
  - TTSで音声に変換、それを再生して画像の説明をする
- [Stop]ボタンをクリックすると、カメラの映像が停止


# 各部の実装（抜粋）

説明のために一部抜粋して簡略化しています。全体のソースはGitHubにあります

- [mganeko/visual_sonar](https://github.com/mganeko/visual_sonar)

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

今回の試作では、次のプロンプトを渡して画像を解析させています。

```
  'What is this? Please answer in Japanese.'
```

ちなみに画像についてチャットを続ける場合は、通常のChatと同様に過去のやりとりと新しいメッセージを配列に格納して送ればOKです。

- 最初の画像込みのユーザーメッセージ
- アシスタントの応答メッセージ
- 次のユーザーからのメッセージ
- それに対するアシスタントの応答メッセージ
- さらにユーザーからのメッセージ...



## TTSでテキスト読み上げ

OpenAIのTTS(text-to-speech) APIを使って、テキストを音声に変換しています。

```js
async function textToSpeech(text, apiKey) {
  const apiUrl = 'https://api.openai.com/v1/audio/speech';

  // -- build header --
  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
  };

  // --- build body ---
  const bodyJson = {
    model: 'tts-1',
    input: text,
    voice: "alloy",
  };
  const body = JSON.stringify(bodyJson);

  // --- request ---
  const res = await fetch(apiUrl, {
    method: "POST",
    headers: headers,
    body,
  }).catch(e => {
    // エラー処理
  });

  // エラー判定
  if (!res.ok) {
    // エラー処理
  }

  const responseBlob = await res.blob();
  return responseBlob;
}
```


## Audio要素で再生

TTS APIで取得したBlobを、Audio要素で再生します。

```js
async function playbacBlobAsync(audioElement, blob) {
  const blobUrl = URL.createObjectURL(blob);
  audioElement.src = blobUrl;
  audioElement.onended = (evt) => {
    URL.revokeObjectURL(blobUrl);
  };
  await audioElement.play();
}
```

また、iOSではユーザー操作が無いとAudio要素で音声が再生できないので、最初にユーザーがボタン操作をした段階で、次のようにAudio要素で再生を試みておきます。

```js
function preparePlay(audioElement) {
  audioElement.play().catch(err => { console.log('prepareAudio'); }); // エラーが発生するが無視OK
  audioElement.pause();
}
```


# 今後やりたいこと


- 1つキャプチャー画像に対して、複数回のやりとりをしたい
- 目の不自由な人が使えるように、アクセシビリティに配慮した作りにしたい
  - 音声で指示が出せる
  - 音声で画像について追加の質問ができる
  - ※ アクセシビリティはOSの機能を利用するのが良いか、独自に音声でのやりとりを実装するのが良いか、要検討



