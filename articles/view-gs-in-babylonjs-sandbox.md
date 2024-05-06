---
title: "Scaniverseで撮影したGaussian SplattingをBabylon.jsのサンドボックスで表示させるまで" # 記事のタイトル
emoji: "🥽" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["iPhone", "gaussiansplatting"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---

# はじめに

ちょっと前から、iPhoneで3Dスキャンができるアプリ「Scaniverse」が、Gaussian Splattingをサポートするようになりました。

- [Scaniverseが3D Gaussian Splattingをサポート](https://nianticlabs.com/news/scsniverse-3dgaussian?hl=ja)

これを[Babylon.js](https://www.babylonjs.com)を使ってWebブラウザで見てみました。

### 今回のスキャン結果

![スキャン結果](/images/gs_water.jpg =400x)


# サンドボックスを使う

Babylon.jsでは、ブラウザ上で簡単に3Dモデルを見ることができるサンドボックスを提供しています。

- https://sandbox.babylonjs.com

.glb, .obj, などの3Dデータだけでなく、Gaussian Splattingのデータ(.ply, .splat)も表示することができます。


## そのままアップロード

ScaniverseからGaussian Splattingのモデル(.ply)をエクスポートし、PCにコピーします。
WebGLに対応したブラウザでサンドボックスにアクセスし、PCにコピーした.plyファイルをドラッグ＆ドロップすればブラウザ上で3Dデータを見れるはずです。

ところが実際に表示されるのは、こんな謎の球体です。


![謎の球体](/images/sandbox_gs_org.png =400x)

どうやらScaniverseで作られる.plyファイルは、次のように中心にスキャン対象が小さく存在し、かなり距離が離れた外周を、背景が取り囲んでいるようです。中を覗くと次のような形で、水色が背景部分、赤がスキャン対象のイメージです。

![断面図](/images/ball-in-ball.png =400x)


## Scaniverseで切り抜き

最近のScaniverseのアップデートで、Gaussian Splattingの切り抜きできるようになりました。EDIT - CROP で切り抜きができます。

上から（Top）と、横から（FRONT, LEFT, RIGHTのやりやすいもの）で切り抜くことで、対象物だけのデータを取り出すことができます。

![top](/images/water_cropping_top.jpg =300x)

![front](/images/water_cropping_front.jpg =300x)


## サンドボックスで表示

切り抜いた3Dデータを.plyに出力し、再びBabylon.jsのサンドボックスにドラッグ＆ドロップすると、無事3Dで表示されるようになりました。

![cropped](/images/sandbox_gs_cropcrop.png)


# Super Splatを用いてブラウザで編集

こちらのサイトを使って、.plyファイルをブラウザ上で編集することができます。Scanverseアプリ上よりもより細かく不要な部分を除去することができます。

- https://playcanvas.com/supersplat/editor

## plyの読み込み

左下から.ply ファイルを指定して読み込むと、球体が表示されます。

![splats-ball](/images/supersplat_ball.png)

それをグーっとズームすると、中心に対象物が現れます。

![splats-zoom](/images/supersplat_zoom.jpg)

## plyの編集

編集方法は複数ありますが、1例として次の方法があります。

(1) 左の「SELECTION」から「Brush」を選び、残したい対象物を塗りつぶす

  ![splats-brush](/images/supersplat_brush.png)

(2) 左の「SELECTION」の「Invert」をクリックすると、選択が反転し、周辺が選択される

  ![splats-invert](/images/supersplat_invert.png)


(3) 「Delete Selected Splats」をクリックすると、選択された周辺部分が削除される

  ![splats-clean](/images/supersplat_deleted.png)

(4) または削除したい部分をBrushで塗りつぶせば、そのまま「Delete Selected Splats」をクリックして、選択した箇所が削除する

これを向きを変えながら何度か繰り返せば、欲しい部分だけ残すことができます。

## plyのエクスポート

「EXPORT TO」の「Ply file」をクリックすれば、編集後の.plyファイルをダンロードすることができます。

![splats-export](/images/supersplat_export.jpg)

## サンドボックスで表示

ダウンロードした.plyをBabylon.jsのサンドボックスにドラッグ＆ドロップすると、編集後の状態を表示することができます。

![sansbox-splats-clean](/images/sansbox_after_supersplat.png)

# 終わりに

最近のScaniverseのバージョンアップで、手軽にGaussian Splattingを楽しむことができるようになりました。そこで初心者が戸惑う（私が戸惑った）編集方法について紹介しました。

今後はbabylon.jsを使って自分で簡単なアプリケーションを作ってみる予定です。

