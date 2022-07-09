---
title: "Chrome M104で実装されるRegion Captureを試してみた" # 記事のタイトル
emoji: "📹" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["WebRTC", "Chrome"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

Chrome M104のWebRTC関連のリリースノートに、「Region Captureが使えるようになる」と書いてあると耳にしたので、Chrome Canary 105で試してみました。
- [WebRTC M104 Release Notes](https://groups.google.com/g/discuss-webrtc/c/PZxgk-aUFhw)

# Region Capture

Chromeをはじめとするモダンブラウザでは、画面共有の機能があります。
-  navigator.mediaDevices.getDisplayMedia()
共有対象として、画面全体や、ウィンドウ、(Chromeの場合)ブラウザのタブが選択できます。

タブを選択したときに特定の領域だけを切り抜いて共有するのが、今回のRegion Captureです。領域は座標で直接指定するのではなく、DOMエレメントを使って作成します。

# デモ

早速動きを見てみましょう。こちらにデモを用意しました。Chrome M104以降でアクセスしてください。(※2022年7月現在、Chrome安定版は103なので動きません)
- GitHub pages:　https://mganeko.github.io/region_capture/
- ソース: https://github.com/mganeko/region_capture

## 操作方法
- Chrome M104以降で、https://mganeko.github.io/region_capture/ を開く
- [start capture]ボタンをクリック
- [現在のタブ/This Tab]を選択
- [共有/Share]をクリック

![共有開始](/images/start_capture.png)

- &lt;div&gt;に囲まれたテキスト、およびテキストエリアのみが共有され、上のビデオ要素に表示される
- テキストエリアを編集すると、その様子がビデオ要素にも反映される

![共有中](/images/while_region_capture.png)

- [stop capture]ボタンをクリックすると、共有が停止






# 参考

- リリースノート:WebRTC M104 Release Notes
  - https://groups.google.com/g/discuss-webrtc/c/PZxgk-aUFhw
- Chrome公式記事とデモ:
  - https://developer.chrome.com/docs/web-platform/region-capture/
  - https://region-capture-demo.glitch.me/
- Region Captureの仕様:
  - https://w3c.github.io/mediacapture-region/
