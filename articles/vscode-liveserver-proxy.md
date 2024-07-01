---
title: "VS Code + Live Serverで開発中に、CORS対応されてないAPIを呼び出す際に役立つproxy機能" # 記事のタイトル
emoji: "🚀" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["VS Code", "CORS", "proxy"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---

# どんな時に使うのか？

手軽にWebサーバーと立てるには、VS Code の機能拡張である[Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)が便利です。

JavaScriptからfetch()を使ってWebAPIを呼び出すケースは頻繁にありますが、API側がCORS対応していない場合、ブラウザーがAPI呼び出しを弾いてしまいます。
例えばAPI側がPython等のコードから呼び出すことを想定していて、ブラウザからの呼び出しを想定していないケースで起こります。

本番サービスではリバースプロキシや中継サーバーを挟んで対処することになりますが、開発環境では手軽に済ませたいです。そんな時に、Live ServerのProxy機能が役に立ちます。

# Proxy機能の概要

今回の用途では、次のようにクライアント(JavaScriptのコード)とサーバー(WebAPI)の、間にLiveServerが入って通信の中継を行います。それによってCORSが発生していないようにブラウザには見えるようになります。

![proxy_flow](/images/proxy_flow.png)

# Live　Server の設定

機能拡張の歯車マークから、「機能拡張の設定」を開きます。

![setting](/images/liveserver.png)

設定の中から、Live Server > Settings Proxy を探し、詳細を設定します。

![proxy](/images/liveserver_proxy.png)

- enable: true （proxy機能を有効にする場合）
- baseUri: LiveServerのWebサーバー上の相対uri
- proxyUri: 転送先のuri

ポートがデフォルトの5500のままの場合、この図の例では次のようにLiveServerを経由してアクセスすることが出来ます。

- ブラウザーのJS → `http://localhost:5500/searchapi` → `https://api.example.com/search`


# 参考

- [CORS非対応APIに、PROXYを中継して通信を行う](https://zenn.dev/sohhakasaka/articles/41aa0fd95d3c0c)



