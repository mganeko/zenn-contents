---
title: "iPhone15 Proの空間ビデオをMeta Questで見るには" # 記事のタイトル
emoji: "🥽" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["iPhone", "MetaQuest"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

これは非公式[Infocom Advent Calendar 2023](https://qiita.com/advent-calendar/2023/infocom)の23日目の記事です。

# 空間ビデオとは

空間ビデオ(Spatial Video)は、来年発売と言われるAppleの｢Apple Vision Pro｣用の3D動画です。
最近リリースされたiOS 17.2から、iPhone15 Pro/iPhone15 Pro Maxで撮影可能になりました。

2023年12月現在Apple Vision Proは未発売のため、Spatial Videoを見ることはできません。が、Meta QuestのようなVRゴーグルがあれば、無理矢理見ることができます。

# 空間ビデオをMetaQuestで見るまで

手順は次の通りです。

- iPhone15 Proで、空間ビデオを撮影
- 空間ビデオを、ステレオペアの動画に変換
- 動画をMetaQuestにコピーする
- MetaQuestで動画を見る

## iPhone15 Proで、空間ビデオを撮影

- iOS 17.2にアップデートする
- 「設定」の「カメラ」-「フォーマット」から、「Apple Vision Pro用の空間ビデオ」をオンにする
- カメラアプリでビデオを撮影
  - 「空間ビデオ」アイコンをタップ
  - iPhoneを横向きにして、ビデオを録画

![空間ビデオ](/images/spatial_on.jpeg =300x)

## ステレオペアの動画に変換

空間ビデオは左眼用、右眼用の映像が1つの動画ファイルに埋め込まれていますが、そのままでは通常の動画のようにしか見えません。そこで、左右の映像を1枚に並べた「ステレオペア動画」(Side-by-Side形式)に変換します。

変換には今回はiPhone用の有料アプリ「Spaitial Video Converter」を使いました。

- [Spaitial Video Converter](https://apps.apple.com/jp/app/spatial-video-converter/id6471887553)
  - 300円 (2023年12月)

変換した動画は、1枚の動画の中に左右の映像が埋め込まれています。裸眼立体視（平行法）ができる人なら、そのままでも立体映像を見ることができます。ただし映像は水平方向に圧縮された状態です（縦長に見える）

![ステレオペア動画](/images/sidebyside.jpeg =400x)

## 動画をMeta Questにコピー

今回は母艦としてIntel Mac(OSはVentura)を使いました。（Windows PCでも可能です）

- iPhone → Macに動画を取り込み （Macの写真アプリを利用)
- Mac → Meta Questに動画をコピー
  - [Android File Transfer](https://www.android.com/filetransfer/) を利用
  - ※VenturaやSonomaではうまく動かないケースもある様子

## Meta Questで動画を見る

今回はSKYBOX VR PLAYERを利用しました。以前に入手したアプリでしたが、今見たら有料でした。

- [SKYBOX VR PLAYER](https://www.meta.com/ja-jp/experiences/2063931653705427/)
  - 990円 (2023年12月)

水平方向の圧縮は解消され、立体映像を楽しむことが出来ます。感想としては「映像はキレイ、立体感は控えめ」でした。


# まとめ

せっかく撮れるようになった空間ビデオ（3Dビデオ）を、50万円のApple Vison Pro無しでも今すぐ見ることができます。

- MetaQuest2 ... 4万円
- iPhoneアプリ ... 300円
- Meta Questアプリ ... 990円

ちなみに私はMeta Quest(初代Qculus Quest)を使いました。Meta Quest2/3でも問題なく見れるはずです。持っている方はお試しくあれ。

