---
title: "M1 MacでAirLLMを使ってElyza-13bを動かしてみた" # 記事のタイトル
emoji: "🦙" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["macOS", "LLM", "llama"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
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

# AirLLM

AirLLMは、巨大なLLMモデルをメモリが少ないGPUで実行可能にするライブラリです。モデル全体をメモリに載せるのではなく、計算するレイヤーごとに分割してストレージからGPUメモリに載せることで、少ないGPUメモリで実行可能にしているようです（その分オーバーヘッドがあり、実行には時間がかかる）

- [Unbelievable! Run 70B LLM Inference on a Single 4GB GPU with This NEW Technique](https://ai.gopubby.com/unbelievable-run-70b-llm-inference-on-a-single-4gb-gpu-with-this-new-technique-93e2057c7eeb)
- [GitHub lyogavin/Anima/air_llm](https://github.com/lyogavin/Anima/tree/main/air_llm)

今回対象としている13Bのモデルなら、十分実行可能なはずです。

またAirLLMはApple siliconをサポートしているのも特徴です。「MLX」というApple silicon用のNumPyライクなライブラリを利用しています。

- [MLX](https://ml-explore.github.io/mlx/build/html/index.html)
  - [GitHub](https://github.com/ml-explore/mlx)

MLXを使う場合は微妙に書き方が変わるようです。こちらのノートブックが参考になります。

- [run_on_macos.ipynb](https://github.com/lyogavin/Anima/blob/main/air_llm/examples/run_on_macos.ipynb)

# 動かしてみる

Python 3.11.7 で動作させています。

## モジュールのインストール

必要なモジュールをインストールします。

```
pip install torch torchvision
pip install mlx

pip install airllm
```

## サンプルコード

```py
# elyze_airllm_mac.py

from airllm import AutoModel
import mlx.core as mx
import time

# モデル名を指定
#model_name = "elyza/ELYZA-japanese-Llama-2-7b-fast-instruct"
model_name = "elyza/ELYZA-japanese-Llama-2-13b-fast-instruct"

MAX_LENGTH = 128
MAX_NEW_TOKENS = 20

# モデルの準備
model = AutoModel.from_pretrained(model_name)


# -- 入力テキスト --
# input_text = [
#     '富士山の高さは？'
# ]
input_text = '富士山の高さは？'

# -- トークナイズ --
def tokenize(model, text):
    input_ids = model.tokenizer(text,
        # return_tensors="pt", # NG
        return_tensors="np", # OK

        return_attention_mask=False,
        truncation=True,
        max_length=MAX_LENGTH,
        #padding=False
    )
    return input_ids

# -- 生成 --
def generate(model, input_ids):
    generation_output = model.generate(
        mx.array(input_ids['input_ids']),
        max_new_tokens=MAX_NEW_TOKENS,
        use_cache=True,
        return_dict_in_generate=True
    )
    return generation_output

# -- 推論の実行 --
def query(model, text):
    input_ids = tokenize(model, text)
    generation_output = generate(model, input_ids)
    return generation_output

# --- main ---
start = time.process_time()
output = query(model, input_text)
end = time.process_time()
print('----------------')
print(output)
print('--- ', end - start, ' sec ---')

```

## 実行

初回実行時はモデルがダウンロードされます。私の環境では数十分かかりました。

- ダウンロード場所: ~/.cache/huggingface/hub/_モデル名_

結果は次のようになりました。

```
- 富士山の高さは3776.12 mです。</s><s>
---  287.62618599999996  sec ---
```

微妙に前後に余計なものが生成されていますが、動かすことができました。実行時間は20トークンで5分弱ということで、実用的には問題ありです。

#  終わりに

AirLLMのおかげで、自分のM1 Macでも高性能のLLMを動かすことができました。実行時間はまだまだですが、今後も様々な手法/ライブラリが出てきて、普通のローカルマシンでも快適に利用できるようになる日が来ることを期待しています。

## 関連記事

- [M1 Macでllama.cppを使ってElyza-13bを動かしてみた](https://zenn.dev/mganeko/articles/llamacpp-elyza-mac)
