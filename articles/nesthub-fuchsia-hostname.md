---
title: "OSがfuchsiaになったNestHubのホスト名の調べ方" # 記事のタイトル
emoji: "🌹" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["NestHub", "fucshia", "mDNS"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---



# はじめに

スマートディスプレイのGoogle NestHubのOSが、徐々にfuchsia（フクシア）にアップデートされています（参考：[ITmedia](https://www.itmedia.co.jp/news/articles/2105/26/news054.html)）。OSの種類が自動アップデートで置き換えるのはなかなかアグレッシブですが、基本的な機能では特に問題は耳にしてません。

我が家のNestHubも最近アップデートが来てfuchsiaに置き換わっていました。ところがその影響で自分で作り込んでいる連携アプリが一部動かなくなっていました。

今回その原因を調査してたので、誰かの参考になればと記事を書きました。


# 何が起きたか

自作の連携アプリはNode.jsで作っています。npmモジュール [castv2-client](https://www.npmjs.com/package/castv2-client)を利用し、Google Castの機能を使って音声をGoogle Home/Google NestHubから流しています。

最近（2021年8月）にNestHubから音声が流れなくなっていることに気がつきました。Google Home Miniからは問題なく流れています。正確にいつから起きているのかは分かりませんが、それと前後してNestHubのOSがアップデートされているようです。何か関連があるかも？ と調査を開始しました。

# 原因

自作アプリではデバイスのホスト名をmDNSを利用して「xxxxxx.local」形式で指定しています。この記事のタイトルにもあるように、今回のfuchsiaへのアップデートの結果、mDNS上のホスト名が変わってしまったようです。そのため、もともと使っていたホスト名では到達できずに、音声castに失敗していました。

元のホスト名が使えなくなったのは、ターミナルからpingで到達しなくなっていたので判明しました。


# 対処

fuchsiaになって変わってしまったNestHubのホスト名を改めて調べました。

## fuchsiaより前のホスト名の調べ方(Mac)

私はMacを使っていますが、dns-sdを使って次のようにホスト名を推定していました。

```
$ dns-sd -B _googlezone._tcp
Timestamp     A/R    Flags  if Domain               Service Type         Instance Name
18:45:38.260  Add        2  11 local.               _googlezone._tcp.    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx
^C
```

この場合、「xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx.local」がGoogle Homeや以前のNestHubのホスト名でした。

## fuchsiaのホスト名の調べ方（Mac）

fuchsiaにアップデート後は、上記の対応付ルールは無くなりました。ホスト名は別途調べる必要があります。同じくdns-sdを使って追加の操作をすることで、無事取得することができました。

```
$ dns-sd -L xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx _googlezone._tcp
Lookup xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx._googlezone._tcp.local
DATE: ---Sun 29 Aug 2021---
18:53:21.356  ...STARTING...
18:53:21.358  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx._googlezone._tcp.local. can be reached at fuchsia-xxxx-xxxx-xxxx.local.:10001 (interface 11)
^C
```

この結果、ホスト名は「fuchsia-xxxx-xxxx-xxxx.local」ということが分かりました。


## アプリで調べる(Mac)

Macの場合、もっと便利なアプリがあります。こちらを使えば簡単にホスト名を調べることができます。

- Discovery - DNS-SD Browser [App Store]( https://apps.apple.com/us/app/discovery-dns-sd-browser/id1381004916)

## Linuxでのホスト名を調べる

Linuxでは、mDNSのサービス/ツールであるavahiで調べることができます。

```
$ avahi-browse -r _googlezone._tcp
=  wlan0 IPv4 xxxxxxxx-xxxx-xxxx-xxxx-xxxx     _googlezone._tcp   local
   hostname = [fuchsia-xxxx-xxxx-xxxx.local]
   address = [192.168.0.xx]
   port = [10001]
...
```

ホスト名は「fuchsia-xxxx-xxxx-xxxx.local」になります。

## Node.jsで調べる（Windows対応）

Windowsで調べる方法を探しましたが、AppleのiTunesと一緒にインストールされるBonjour機能を利用する方法があるようです。

別の方法として、今回はNode.js + [mdns-js](https://www.npmjs.com/package/mdns-js)モジュールを利用したコードを作成しました。

###  準備

- Node.js, npm をインストール
- npm install mdns-js を実行し、モジュールをインストール

### ソースコード

次のソースを例えば browser.js として保存します。

```js

const mdns = require('mdns-js');
const TIMEOUT = 5000; //5 seconds

//const browser = mdns.createBrowser(); //defaults to mdns.ServiceType.wildcard
//const browser = mdns.createBrowser(mdns.tcp('googlecast'));
const browser = mdns.createBrowser(mdns.tcp('googlezone')); // サービス名

browser.on('ready', function onReady() {
  console.warn('browser is ready');
  browser.discover();
});

browser.on('update', function onUpdate(data) {
  console.log('data:', data);
});

//stop after timeout
setTimeout(function () {
  browser.stop();
}, TIMEOUT);

```

GitHub ... [https://github.com/mganeko/mdns_browser](https://github.com/mganeko/mdns_browser)

### 実行

Windows コマンドプロンプトの場合

```
> node browser.js | find "fuchsia"
browser is ready
  host: 'fuchsia-xxxx-xxxx-xxxx.local',
```

Windows PowerShellの場合

```
> node browser.js | Select-Sring "fuchsia"
browser is ready
  host: 'fuchsia-xxxx-xxxx-xxxx.local',
```


Macの場合

```
$ node browser.js | grep fuchsia
browser is ready
  host: 'fuchsia-xxxx-xxxx-xxxx.local',
```

※同じ情報が複数回表示されることがあります

このように、[mdns-js](https://www.npmjs.com/package/mdns-js)を利用してホスト名を調べる事ができます。



# まとめ

IoT機器のファムウェアアップデートはなかなか厄介ですが、Google HomeやNestHubといったスマートスピーカー/スマートディスプレイは勝手にアップデートしてくれます。日々進化していく様子は楽しいのですが、時々思わぬ変更があリ、標準から外れた使い方をしている場合には困ることがあります。

今回はホスト名が変わるという大きめな変更がありましたが、IoT機器といってもいろいろなネットワーク技術やWeb技術の上に成り立っているので、今回はmDNSを使って調べることができました。


