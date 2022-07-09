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






# 参考

- リリースノート:WebRTC M104 Release Notes
  - https://groups.google.com/g/discuss-webrtc/c/PZxgk-aUFhw
- Chrome公式記事とデモ:
  - https://developer.chrome.com/docs/web-platform/region-capture/
  - https://region-capture-demo.glitch.me/
- Region Captureの仕様:
  - https://w3c.github.io/mediacapture-region/
