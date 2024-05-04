---
title: "Scaniverseで撮影したGaussian SplatingをBabylon.jsのサンドボックスで表示させるまで" # 記事のタイトル
emoji: "🥽" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["iPhone", "gaussiansplatting"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

ちょっと前から、iPhoneで3Dスキャンができるアプリ「Scaniverse」が、Gaussian Splatingをサポートするようになりました。

- [Scaniverseが3D Gaussian Splattingをサポート](https://nianticlabs.com/news/scsniverse-3dgaussian?hl=ja)

これを[Babylon.js](https://www.babylonjs.com)を使ってWebブラウザで見てみました。

### 今回のスキャン結果

![スキャン結果](/images/gs_water.jpg =400x)


# サンドボックスを使う

Babylon.jsでは、ブラウザ上で簡単に3Dモデルを見ることができるサンドボックスを提供しています。

- https://sandbox.babylonjs.com

.glb, .obj, などの3Dデータだけでなく、Gaussian Splattingのデータ(.ply, .splat)も表示することができます。


## そのままアップロード

ScaniverseからGaussian Splatingのモデル(.ply)をエクスポートし、PCにコピーします。
WebGLに対応したブラウザでサンドボックスにアクセスし、PCにコピーした.plyファイルをドラッグ＆ドロップすればブラウザ上で3Dデータを見れるはずです。

ところが実際に表示されるのは、こんな謎の球体です。


![謎の球体](/images/sandbox_gs_org.png =400x)

どうやらScaniverseで作られる.plyファイルは、次のように中心にスキャン対象が小さく存在し、かなり距離が離れた外周を、背景が取り囲んでいるようです。中を覗くと次のような形で、水色が背景部分、赤がスキャン対象のイメージです。

![断面図](/images/ball-in-ball.png =400x)


## Scaniverseで切り抜き

最近のScaniverseのアップデートで、Gaussian Splatingの切り抜きできるようになりました。EDIT - CROP で切り抜きができます。

上から（Top）と、横から（FRONT, LEFT, RIGHTのやりやすいもの）で切り抜くことで、対象物だけのデータを取り出すことができます。

![top](/images/water_cropping_top.jpg =300x)

![front](/images/water_cropping_front.jpg =300x)


### サンドボックスで表示

切り抜いた3Dデータを.plyに出力し、再びBabylon.jsのサンドボックスにドラッグ＆ドロップすると、無事3Dで表示されるようになりました。

![cropped](/images/sandbox_gs_cropcrop.png =400x)


