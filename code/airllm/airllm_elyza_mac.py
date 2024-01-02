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


def generate(model, input_ids):
    generation_output = model.generate(
        mx.array(input_ids['input_ids']),
        max_new_tokens=MAX_NEW_TOKENS,
        use_cache=True,
        return_dict_in_generate=True
    )
    return generation_output

def q(model, text):
    # 推論の実行
    input_ids = tokenize(model, text)
    generation_output = generate(model, input_ids)
    return generation_output

# --- main ---
start = time.process_time()
output = q(model, input_text)
end = time.process_time()
print('----------------')
print(output)
print('--- ', end - start, ' sec ---')
