---
title: "NestHubがfuchsiaになって、ホスト名が変わった件" # 記事のタイトル
emoji: "🌹" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["NestHub", "fucshia", "mDNS"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---



# はじめに

スマートディスプレイのGoogle NestHubのOSが、徐々にfuchsia（フクシア）にアップデートされています（参考：[ITmedia](https://www.itmedia.co.jp/news/articles/2105/26/news054.html)）。OSの種類が自動アップデートで置き換わるのいうのはなかなかアグレッシブですが、基本的な機能では特に問題は耳にしてません。

我が家のNestHubも最近アップデートが来てfuchsiaに置き換わっていました。ところがその影響で自分で作り込んでいる連携アプリが一部動かなくなっていました。

今回その原因を調査して対処したので、誰かの参考になればと記事を書きました。


# 何が起きたか

自作の連携アプリはNode.jsで作っています。npmモジュール [castv2-client](https://www.npmjs.com/package/castv2-client)を利用し、Google Castの機能を使って音声をGoogle Home/Google NestHubから流しています。

最近（2021年8月）にNestHubから音声が流れなくなっていることに気がつきました。Google Home Miniからは問題なく流れています。正確にいつから起きているのかは分かりませんが、それと前後してNestHubのOSがアップデートされているようです。何か関連があるかも？ と調査を開始しました。

# 原因

自作アプリではデバイスのホスト名をmDNSを利用して「xxxxxx.local」形式で指定しています。今回の



# 対処

# まとめ



