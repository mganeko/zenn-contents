---
title: "M1 Macでllama.cppを使ってElyza-13bを動かしてみた" # 記事のタイトル
emoji: "🦙" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["macOS", "LLM", "llama"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---

# はじめに

「ELYZA-japanese-Llama-2-13b」シリーズを、llama.cppを使ってM1 Mac (MacBook Air M1 16GB)で動かしてみました。
llama.cppは、Meta社のLLaMA/LLaMa 2を動かすためのC/C++実装です。

- [llama.cpp](https://github.com/ggerganov/llama.cpp)

# モデルの変換＆量子化

llama.cppでモデルを動かすには、gguf形式への変換が必要です。また13bのモデルは大きすぎるので、量子化してサイズを小さくする必要があります。
momongaさんが変換＆量子化済みのモデルを公開しているので、そちらを使わせていただきました。

- [mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf](https://huggingface.co/mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf/tree/bd8556cccb46dda6250c112c680aa8c76e6e3000)

# 準備

## llama.cppのビルド

```
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
make -j
```

## モデルのダウンロード

8bit, 6bit, 5bit, 4bit量子化のモデルが公開されていますが、8/6bitでは私の環境には大きすぎるようです。5bitでギリギリ動いたので、そちらをダウンロードします。

```
wget https://huggingface.co/mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf/resolve/bd8556cccb46dda6250c112c680aa8c76e6e3000/ELYZA-japanese-Llama-2-13b-fast-instruct-q5_0.gguf
```

# 実行

```
./main -m 'ELYZA-japanese-Llama-2-13b-fast-instruct-q5_0.gguf' -n 32 -p '富士山の高さは？'
```

出力の例
```
 富士山の高さは？
A.3776.12 m (2020年8月現在の値) [end of text]

llama_print_timings:        load time =     767.14 ms
llama_print_timings:      sample time =      22.81 ms /    23 runs   (    0.99 ms per token,  1008.37 tokens per second)
llama_print_timings: prompt eval time =     551.76 ms /     7 tokens (   78.82 ms per token,    12.69 tokens per second)
llama_print_timings:        eval time =    3490.02 ms /    22 runs   (  158.64 ms per token,     6.30 tokens per second)
llama_print_timings:       total time =    4080.75 ms
```

実行は4秒程度です。生成される内容はマチマチで、おかしな結果になる場合もあります。

# まとめ

llama.cppを使うことで、M1 Mac上でElyzaの13Bのモデルを動かすことができました。量子化しているので同条件ではありませんが、AirLLMを使った場合よりもはるかに高速です。その分、出力結果は不安定になりました。

- [M1 MacでAirLLMを使ってElyza-13bを動かしてみた](https://zenn.dev/mganeko/articles/airllm-elyza-mac)

「PowerInfer」という手法も登場しているようなので、精度と実行時間の両立ができるのようになることを期待しています。

