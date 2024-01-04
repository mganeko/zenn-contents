---
title: "M1 Macでnode-llama-cppを使ってElyza-13bを動かしてみた" # 記事のタイトル
emoji: "🦙" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["macOS", "LLM", "llama", "node.js"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

「ELYZA-japanese-Llama-2-13b」シリーズを、llama.cppのNode.jsバインディングである「node-llama-cpp」を使ってM1 Mac (MacBook Air M1 16GB)で動かしてみました。

- [node-llama-cpp](https://github.com/withcatai/node-llama-cpp)
- [llama.cpp](https://github.com/ggerganov/llama.cpp)

# 準備

- llama.cppをインストール
  - 参考： [M1 Macでllama.cppを使ってElyza-13bを動かしてみた - llama.cppのビルド](https://zenn.dev/mganeko/articles/llamacpp-elyza-mac#llama.cppのビルド)
- モデルをダンロード
  - [4bit量子化モデル](https://huggingface.co/mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf/resolve/65774113f0e6849051d3669643060e0a650c7d61/ELYZA-japanese-Llama-2-13b-fast-instruct-q4_0.gguf)を利用

# node-llama-cppを利用するには

## モジュールのインストール

適切なフォルダを作り、その中でモジュールをインストール

```
npm install node-llama-cpp
```

## モデルファイルの準備

```
mkdir models
```

modelsフォルダの中に、ダウンロードしたモデル（LYZA-japanese-Llama-2-13b-fast-instruct-q4_0.gguf）を配置する（コピー or 移動 or シンボリックリンク）

## サンプルコード

[Getting Started](https://withcatai.github.io/node-llama-cpp/guide/#getting-started)を参考に、次のコードを作成

```mjs
// example.mjs
mport {fileURLToPath} from "url";
import path from "path";
import {LlamaModel, LlamaContext, LlamaChatSession} from "node-llama-cpp";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const model = new LlamaModel({
    modelPath: path.join(__dirname, "models", "ELYZA-japanese-Llama-2-13b-fast-instruct-q4_0.gguf")

});
const context = new LlamaContext({model});
const session = new LlamaChatSession({context});


// ----- チャット ----
const q1 = "富士山の高さは？";
console.log("User: " + q1);
const a1 = await session.prompt(q1);
console.log("AI: " + a1);

const q2 = "エベレストは？";
console.log("User: " + q2);
const a2 = await session.prompt(q2);
console.log("AI: " + a2);

```

## 実行

```
node exmample.mjs
```

実行結果の例
```
User: 富士山の高さは？
AI: 富士山の高さは3776.12 mです。
User: エベレストは？
AI: エベレストは8848 mです。
```
