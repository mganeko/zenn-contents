---
title: "M1 Macでllama.cppを使ってElyza-13bを動かしてみた" # 記事のタイトル
emoji: "🦙" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["macOS", "LLM", "llama"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

「ELYZA-japanese-Llama-2-13b」シリーズを、llama.cppを使ってM1 Mac (MacBook Air M1 16GB)で動かしてみました。

# モデルの変換＆量子化

llama.cppでモデルを動かすには、gguf形式への変換が必要です。また13bのモデルは大きすぎるので、量子化してサイズを小さくする必要があります。
momongaさんが変換＆量子化済みのモデルを公開しているので、そちらを使わせていただきました。

- [mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf](https://huggingface.co/mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf/tree/bd8556cccb46dda6250c112c680aa8c76e6e3000)

# 準備

## llama.cppのビルド

## モデルのダウンロード

8bit, 6bit, 5bit, 4bit量子化のモデルが公開されていますが、8/6bitでは私の環境には大きすぎるようです。5bitでギリギリ動いたので、そちらをダウンロードします。


