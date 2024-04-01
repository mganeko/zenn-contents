---
title: "llama.cppを使って、EvoLLM-JP-v1-10Bを自分で量子化した手順" # 記事のタイトル
emoji: "🦙" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["LLM", "llamacpp"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

SakanaAIから進化的モデルマージという手法を用いたAIモデルが複数公開されています。LLMモデルとしても7Bのモデルと、10Bのモデルが公開されています。

- [進化的アルゴリズムによる基盤モデルの構築](https://sakana.ai/evolutionary-model-merge-jp/)
  - [EvoLLM-JP-v1-7B](https://huggingface.co/SakanaAI/EvoLLM-JP-v1-7B)
  - [EvoLLM-JP-v1-10B](https://huggingface.co/SakanaAI/EvoLLM-JP-v1-10B)
  
これをllama.cppを用いて実行するために8bitに量子化を試みました。

# 7Bモデルの量子化

[llama.cpp](https://github.com/ggerganov/llama.cpp)に含まれる convert.py を用いて、次のようにgguf形式に変換することができました。

```
$ python convert.py ../EvoLLM-JP-v1-7B
```

さらに8bitに量子化します。

```
$ ./quantize ../EvoLLM-JP-v1-7B/ggml-model-f16.gguf ../EvoLLM-JP-v1-7B/EvoLLM-JP-v1-7B-q8_0.gguf q8_0
```

これをllama.cppを使って実行すると、応答を得ることができました。

```
$  ./main-cuda -m '../../models/EvoLLM-JP-v1-7B-q8_0.gguf' -p "### 指示: あなたは役立つアシスタントです。 ### 入力:富士山の高さは？ ### 応答:" -n 256 --n-gpu-layers 50
 
 （途中省略）

 ### 指示: あなたは役立つアシスタントです。 ### 入力:富士山の高さは？ ### 応答:富士山の高さは3,776メートルです。 [end of text]
```

# 10Bモデルの量子化

## gguf化のエラー

同様に10Bモデルをgguf形式に変換しようとすると、エラーが出て失敗してしまいます。

```
$ python convert.py ../EvoLLM-JP-v1-10B
→ ERROR
  assert end - begin == math.prod(shape) * numpy_dtype.itemsize
```

どうやらデータのサイズが理論値と違うと言われているようです。

## ヒント

Webで検索しても対策が見つからず途方に暮れていましたが、X(twitter)上でヒントを見つけました。

@[tweet](https://twitter.com/mutaguchi/status/1771511523493458332)

@[tweet](https://twitter.com/mutaguchi/status/1771540582474596492)

@[tweet](https://twitter.com/mutaguchi/status/1771541412506403085)

