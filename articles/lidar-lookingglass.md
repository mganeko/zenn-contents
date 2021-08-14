---
title: "LiDARでスキャンしたデータをブラウザを使ってLooking Glass Portraitに表示するまで" # 記事のタイトル
emoji: "📺" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["LiDAR", "Looking Glass"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
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

公式のガイド「[Creating Your First HoloPlay.js App](https://docs.lookingglassfactory.com/developer-tools/three/setup#creating-your-first-holoplay-js-app)」と、サンプル「[Load gLTF Model](https://docs.lookingglassfactory.com/developer-tools/three/examples#load-gltf-model)」のソースを参考に実装します。


## シンプルなGLB形式の表示

### 基本のコード例

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

### 実行

実行にはローカルにWebサーバーを立てて、ファイル一式をそこに配置します。
エディターにVS Codeを使っている場合は、[Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)を利用すると便利です。Microsoftからも[Live Preview](https://marketplace.visualstudio.com/items?itemName=ms-vscode.live-server)のプレビュー版が公開されているので、こちらを使うのもありです（試してません）

Looking Glass に表示するには次の手順を踏みます。

- 新しくブラウザのウィンドを開く
- 作成したファイルのURLにアクセスする
  - 例えば http://localhost:5500/simple.html など
- ウィンドウを Looking Glass側に移動する
- ウィンドウの中身をクリックし、最大化する

これでLookig Glassに表示されるハズですが、実際にはほとんどのケースでまともに表示されません。3Dモデルのスケールやセンター位置がバラバラで、表示に適切な値になっていないためです。

次のステップでは、ある程度自動的に簡易補正するコードを追加します。

## GLB形式の簡易補正つき表示

### 簡易補正つきコード例


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
        // -- 簡易補正用 --
        let desiredScale = 0.1; // 目標とするスケール
        let adjustOffset = new THREE.Vector3(0, 0, 0); // for Polycam
        //let adjustOffset = new THREE.Vector3(0, -0.15, 0); // for Scaniverse
        //let adjustOffset = new THREE.Vector3(0, -0.04, 0); // for 3dScanner App

        // -- バウンディングボックスを使ってスケール補正を計算 --
        let boundigbox = new THREE.Box3().setFromObject(gltf.scene);
        let d = boundigbox.min.distanceTo(boundigbox.max);
        let scale = desiredScale * (1 / (d/2));
        
        // -- センター位置補正を計算 --
        let center = new THREE.Vector3().addVectors(boundigbox.min, boundigbox.max);
        let offset = center.clone();
        offset.multiplyScalar(scale);
        offset.add(adjustOffset);

        //console.log("gltf distance, scale, BondingBox:", d, scale, boundigbox);
        //console.log("center, offset", center, offset);
        
        // -- モデルのスケール、位置を補正 --
        gltf.scene.scale.setScalar(scale);
        gltf.scene.rotation.y = Math.PI;
        gltf.scene.position.add(offset);

        // -- シーンにモデルを追加 --
        model.add(gltf.scene);
        model.rotation.x = Math.PI /180 * 15; // 仰角を調整
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

### スケールの補正

スケールの補正には、バウンディングボックス（モデルを囲う直方体）を取得し、その対角線を結ぶ直接の長さが程よい長さになるように補正しています。

```js
      let desiredScale = 0.1; // 目標とするスケール

      // -- バウンディングボックスを使ってスケール補正を計算 --
      let boundigbox = new THREE.Box3().setFromObject(gltf.scene);
      let d = boundigbox.min.distanceTo(boundigbox.max);
      let scale = desiredScale * (1 / (d/2));
```

程よい長さ(desiredScale)は、サンプル「[Load gLTF Model](https://docs.lookingglassfactory.com/developer-tools/three/examples#load-gltf-model)」に含まれるモデルの大きさを参考に決めています。
もし期待する大きさにならない場合は、desiredScaleを調整してください。


### センター位置の補正

センター位置の補正にも、バウンディングボックスを利用しています。バウンディングボックスの中心が、ラッパーの中心に来るように offset を計算しています。

```js
      // -- センター位置補正を計算 --
      let center = new THREE.Vector3().addVectors(boundigbox.min, boundigbox.max);
      let offset = center.clone();
      offset.multiplyScalar(scale);
      offset.add(adjustOffset);
```

実際には、センター位置をずらす量もスケール補正をかけています。さらに、スキャンに使うアプリによってセンター位置の上下（Yの値）が異なっているように見えます。それを補正するために adjustOffset を設定しています。
これは私がスキャンした少ないサンプルで割り出した値なので、みさなんの撮影条件では異なる可能性があります。その場合は、 adjustOffset を調整して、程よい位置に表示されるようにしてください。


# まとめ

Looking Glass Portraitは想像していたよりもはるかに立体感/奥行き感が感じられます。
ポートレートモードで撮影した写真を表示させるだけでも楽しいですが、LiDARで撮影した物体/風景を表示させると、よりその真価を発揮できます。
もし使える機会があったら、ぜひお試しああれ。



