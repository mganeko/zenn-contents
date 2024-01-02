---
title: "M1 MacでAirLLMを使ってElyza-13bを動かしてみた" # 記事のタイトル
emoji: "🦙" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["macOS", "LLM", "llama"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

前日2023年の年末に、Elyzaから「既存のオープンな日本語LLMの中で最高性能」と言われる「ELYZA-japanese-Llama-2-13b」シリーズが公開されました。
これを「70Bのモデルも 4GB GPU カードで推論できる」とうたっているAirLLMを使うことで、M1 Mac (MacBook Air M1 16GB)で動かしてみました。

# ELYZA-japanese-Llama-2-13bシリーズ

これはMeta 社の「Llama 2」シリーズをベースに、日本語テキストの追加学習を行ったモデル群です。
ライセンスは Llama 2 Community License に準拠しており、Acceptable Use Policy に従う限りにおいては、研究および商業目的での利用が可能です。

- [130億パラメータの「Llama 2」をベースとした日本語LLM「ELYZA-japanese-Llama-2-13b」を公開しました](https://note.com/elyza/n/n5d42686b60b7)

今回はシリーズの中から、日本語語彙の追加学習とトークナイザーの効率化、そしてユーザーの指示に従う追加学習を行ったモデルを利用しました。

- [ELYZA-japanese-Llama-2-13b-fast-instruct](https://huggingface.co/elyza/ELYZA-japanese-Llama-2-13b-fast-instruct)



