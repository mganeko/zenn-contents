---
title: "WebRTC (旧)Insertable Streams と ScriptTransforms の相互通信実験" # 記事のタイトル
emoji: "📷" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["webrtc"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---


# WebRTC (()旧)Insertable Stream のおさらい

Chromeでサポートされている映像や音声のエンコード済みで、パケット分割前のデータを取得できる仕組みで、主にEnd-to-End Encryptionの用途で使われます。



- https://www.w3.org/2011/04/webrtc/wiki/images/8/86/WebRTCWG-2020-02-27.pdf P.29〜

- example
  - Page https://webrtc.github.io/samples/src/content/insertable-streams/endtoend-encryption/
  - Code https://github.com/webrtc/samples/tree/gh-pages/src/content/insertable-streams/endtoend-encryption


- 経緯
  - https://groups.google.com/a/mozilla.org/g/dev-platform/c/Gowr5Fx5jng
