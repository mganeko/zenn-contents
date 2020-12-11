---
title: "LiDARでスキャンしたデータをブラウザで表示するまで" # 記事のタイトル
emoji: "📱" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: [LiDAR　a-frame] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

これは非公式[Infocom Advent Calendar 2020](https://qiita.com/advent-calendar/2020/infocom)の記事です。

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
- GLTF形式

スキャナプリからシェア（エクスポート）する際に、形式が選べることが多いです（形式の変換は有料のアプリもあります）

## 3D表示

three.jsなど、WebGLを使ったライブラリを活用します。今回はA-FAMEを使いました（simpleというよりeasy寄り）

- A-FRAME ... https://aframe.io/

# 実装



