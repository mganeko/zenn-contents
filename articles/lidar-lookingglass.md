---
title: "LiDARでスキャンしたデータをLooking Glass Portraitに表示するまで" # 記事のタイトル
emoji: "📺" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["LiDAR", "Looking Glass"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---



# はじめに

Looking Glass Portrait が届いたので、LiDARでスキャンした3Dデータを、ブラウザ+WebGL(three.js)を使って表示してみました。

この記事は「[LiDARでスキャンしたデータをブラウザで表示するまで](https://zenn.dev/mganeko/articles/lidar-aframe)」の続編です。


# 準備

## 動作環境

こちらの環境で実行しています。

- ブラウザ: Chrome 92 (arm64)
- OS: macOS Big Sur (M1)

## HoloPlay Service

Looking Glass Portraitを使うには、まず公式のソフトウェアをインストールし、デバイスのセットアップを済ませておきます。

- HoloPlay Service ... https://lookingglassfactory.com/software#holoplay-service

## スキャンアプリ

アプリは複数ありますが、主にこちらを利用しています。

- Polycam ... データのエクスポート機能は有料
- 3d Scanner App ... 無料
- Scaniverse ... Pro版の機能も2021年8月に無料に

## 3Dデータ

iOSの標準ではデータ形式はUSDZですが、Webブラウザで扱いやすいように他の形式を使います。

- GLB形式(GLTF形式)

スキャナプリからシェア（エクスポート）する際に、形式を選べることが多いです（形式の変換は有料のアプリもあります）

## 3D表示

ブラウザで扱うために、WebGLを使ったライブラリを活用します。今回はthree.jsをベースにした、Looking Glass公式の[holoplay.js](https://docs.lookingglassfactory.com/developer-tools/three)を利用しました。

- Holoplay.js ... https://docs.lookingglassfactory.com/developer-tools/three


### インストール方法

[こちら](https://docs.lookingglassfactory.com/developer-tools/three/setup#quick-install-with-npm)にある通り、node.js + npm の環境を用意した後に、npmでインストールすることができます。

```
$ npm install holoplay
```

あるいは、こちにあるリンクから、ビルド済みのファイルをダウンロードできます。（zip圧縮されているので、解凍して利用してください）

- First Time Usage ... https://docs.lookingglassfactory.com/developer-tools/three/setup#first-time-usage
  - "You can download our bundle here" ... https://s3.amazonaws.com/static-files.lookingglassfactory.com/HoloplayJS/Holoplayjs-1.0.3.zip

※ Holoplay.jsのバージョンが上がるとファイルのURLも変更になるので、最新版をご確認ください。

今回は前者(npm)でインストールした場合を記載します。npmで違う場所にインストールした場合や、直接ファイルをダウンロードをダウンロードした場合は、自分の環境に合わせてパスを変更してください。


# 実装

公式のガイド「[Creating Your First HoloPlay.js App](https://docs.lookingglassfactory.com/developer-tools/three/setup#creating-your-first-holoplay-js-app)」と、サンプルのソース「[](view-source:https://dhtk4bwj5r21z.cloudfront.net/HoloplayJS/examples/gltf/index.html)」を参考に実装します。


## 基本のコード例: GLB形式の表示

GLB/GLTFの場合は、three/examples/js/loaders/GLTFLoader.js を使います。

```html
<!DOCTYPE HTML>
<html>
  <body>
    <script src="node_modules/three/build/three.js"></script>
    <script src="node_modules/holoplay/dist/holoplay.js"></script>
    <script src="node_modules/three/examples/js/loaders/GLTFLoader.js"></script>

    <script>
      // -- カメラ、シーンを用意 --
      const scene = new THREE.Scene();
      const camera = new HoloPlay.Camera();
      const renderer = new HoloPlay.Renderer();
      document.body.appendChild(renderer.domElement);
  
      // -- 光源を用意 --
      const directionalLight = new THREE.DirectionalLight(0xFFFFFF, 1);
      directionalLight.position.set(0, 1, 2);
      scene.add(directionalLight);
      const ambientLight = new THREE.AmbientLight(0xFFFFFF, 0.4);
      scene.add(ambientLight);
  
      // -- GLB形式のモデルを読み込み --
      let model = new THREE.Group(); // モデルをラップして、扱いやすくしてく
      const modelFile = 'path/to/your/model.glb'; // ※モデルのパス(URL)に書き換えてください
      new THREE.GLTFLoader().load(modelFile, (gltf) => {
        model.add(gltf.scene);
        scene.add(model);
      });

      // -- 描画 --
      function update(time) {
        requestAnimationFrame(update);

        // -- モデルを回転する --
        let duration = 20000;
        if (model) {
          model.rotation.y = (Math.PI) *  (time / duration);
        }

        renderer.render(scene, camera);
      }
      requestAnimationFrame(update);
    </script>
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



