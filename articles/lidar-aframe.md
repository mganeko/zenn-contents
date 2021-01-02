---
title: "LiDARでスキャンしたデータをブラウザで表示するまで" # 記事のタイトル
emoji: "📱" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["LiDAR", "a-frame"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---

# はじめに

これは非公式[Infocom Advent Calendar 2020](https://qiita.com/advent-calendar/2020/infocom)の3日目の記事です。

# やりたいこと

LiDARが使えるあの電話機を手に入れたので、早速3Dスキャンを楽しんています。
これをWebブラウザで見れるようにしてみます。

# 利用する要素

## スキャンアプリ

アプリは複数ありますが、主にこちらを利用しています。

- 3d Scanner App ... 無料
- Polycam ... データのエクスポート機能は有料

## 3Dデータ

iOSの標準ではデータ形式はUSDZですが、Webブラウザで扱いやすいように他の形式を使います。

- OBJ形式
- GLTF/GLB形式

スキャナプリからシェア（エクスポート）する際に、形式を選べることが多いです（形式の変換は有料のアプリもあります）

## 3D表示

three.jsなど、WebGLを使ったライブラリを活用します。今回はA-FAMEを使いました（simpleというよりeasy寄り）

- A-FRAME ... https://aframe.io/


# 実装

[A-FRAME](https://aframe.io/)を使うことで、表示だけなら簡単にできます。

![表示例](https://storage.googleapis.com/zenn-user-upload/gagu8v40y0n4dc8f9okzecfuurw8)


## コード例: GLTF/GLB形式

GLTF/GLBの場合は、<a-gltf-model>を使うのが簡単です。

```html
<!DOCTYPE html>
<html>

<head>
  <title>gltf in A-Frame</title>
  <script src="https://aframe.io/releases/1.0.4/aframe.min.js"></script>
</head>

<body>
  <a-scene>
    <a-assets>
      <!-- asset for model file -->
      <a-asset-item id="tree" src="path/some.glb"></a-asset-item>
    </a-assets>

    <!-- Using the asset management system. -->
    <a-gltf-model src="#tree" position="0 0.5 -2" rotation="0 -45 0" scale="0.2 0.2 0.2"></a-gltf-model>

    <a-sky color="#ECECEC"></a-sky>
  </a-scene>
</body>

</html>
```

## コード例: OBJ形式

OBJファイルの場合は、関連するMTLやテクスチャファイル(JPG等)と一緒にWebサーバーに配置します。<a-entity obj-model>を使って表示します。

```html
<!DOCTYPE html>
<html>

<head>
  <title>Obj in A-Frame</title>
  <script src="https://aframe.io/releases/1.0.4/aframe.min.js"></script>
</head>

<body>
  <a-scene>
    <a-assets>
      <!-- asset for model file -->
      <a-asset-item id="tree-obj" src="path/some.obj"></a-asset-item>
      <a-asset-item id="tree-mtl" src="path/some.mtl"></a-asset-item>
    </a-assets>

    <!-- Using the asset management system. -->
    <a-entity obj-model="obj: #tree-obj; mtl: #tree-mtl" position="-0.5 2 -0.5" scale="0.5 0.5 0.5"></a-entity>

    <a-sky color="#ECECEC"></a-sky>
  </a-scene>
</body>

</html>
```

## 面倒なところ

### obj/mtlファイルの読み込みデーエラー

- 3Dデータの読み込みでエラー or 正しく表示されない
- 対策(1) ... 手でファイルを修正する
  - OBJ形式利用時に、テクスチャのマッピングを示すMTLファイルの読み込みでエラー
  - 存在しないテクスチャ(JPG)を参照している箇所を、手動で削除 → 読み込み成功
- 対策(2) ... 他の形式を使う
  - OBJ形式でうまくいかない場合hは、 GLTF/GLB形式を利用→うまくいくケースあり
- 対策(3) ... 他のアプリを使う
  - 3d Scanner Appからエクスポートしたファイルの読み込みに失敗
  - アプリの不具合か設定の不備か、原因は不明

※各ファイル形式のフォーマットを理解すれば根本的な対策できそうですが、そこまではできず。

### カメラと3D物体の位置関係


- 表示するまで、どのような位置に物体が表示されるか予想できない
- 対策 ... ブラウザーでインスペクターを起動してトライ＆エラー
  - インスペクターの起動は [ctrl] + [Alt] + i
  - 要素の位置、スケール、ローテーションを調整
  - →程よい値を割り出し、プロパティに反映

### 3D物体の回転軸の調整

- 3D物体のローテーションを調整した時に、必ずしも中心軸にそって回転しない
  - 特にアプリ側でトリミングしてからエクスポートした場合に発生
  - 回転軸をオフセットする方法が見つからず
- 対策...他のエレメントでラップする
  - 回転は、ラッパー側で行う
  - ラッパーに対する3D物体の相対位置（オフセット）を指定し、回転軸を調整する

```html:抜粋
<!-- 回転は wrap_pbj で行う -->
<a-entity id="wrap_pbj" position="0 0 0" rotation="0 20 0">
  <!-- 3D物体の位置を、wrap_pbjに対しての相対オフセットで指定する -->
  <a-entity id="obj" obj-model="obj: #tree-obj; mtl: #tree-mtl" position="-0.5 0.4 0.5" scale="0.5 0.5 0.5">
  </a-entity>
</a-entity>
```

# まとめ

LiDARで撮影した物体/風景を見るのは楽しいです。
GLTF形式やOBJ形式とA-FRAMEを組み合わせれば、iOSだけでなくいろいろなブラウザで楽しむことができます。



