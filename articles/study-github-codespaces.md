---
title: "ハッカソンでGitHub Codespacesの使い方を学んだ話" # 記事のタイトル
emoji: "🐙" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["GitHub", "Codespaces"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

11月末にグループ会社含む社内ハッカソンが開催され、私も参加してきました。
今回は開発環境として初めてGitHub Codespacesを使ったのですが、ちょっとしたコツをメンターに教わったので、自分の備忘録を兼ねて記事にします。

# GitHub Codespacesとは

[公式ドキュメント](https://docs.github.com/ja/codespaces/overview)によると、Codepacesとは次の通りです。

- codespace は、クラウドでホストされている開発環境です。 構成ファイルをリポジトリにコミットすることで、GitHub Codespaces のプロジェクトをカスタマイズできます (コードとしての構成とよく呼ばれます)。これにより、プロジェクトのすべてのユーザーに対して繰り返し可能な codespace 構成が作成されます。

実体はクラウド上で起動されるコンテナで、ブラウザ内で動くVS Codeから操作することができます。

## Codespacesの起動

GitHubのリポジトリのページから、 「Code」 - 「Codespaces」 - 「Create codespace on master」とクリックすると、クラウド上でコンテナ環境が起動され、ブラウザ上のVS Codeから操作できるようになります。

![start-codespace](/images/start_new_codespace.png =400x)

# ランタイム環境の固定

上記のように既存のリポジトリからCodespecesを起動すると、ランタイム環境が自動に選択されてコンテナが開始します。

私の場合はNode.jsのサーバーのリポジトリから開始したところ、ある時はnode v20が、また別の時にはnode v16がセットアップされ、一部の機能が動かないことがありました。

そこでハッカソンに参加していたメンターに教わり、2つの方法があることがわかりました。


## リモートウィンドウアイコンからの設定

Codespaceを利用しているブラウザ上のVS Codeから操作します。

- 一番左下の「リモートウィンドウアイコン」の「Codesapces」をクリック
- コマンドパレットが開くので、「Add Dev Container Config」を選択
- 選択肢の中から適切な環境を選ぶ
  - .devcontainer/devcontainer.json が追加される
- 環境をリビルドするか確認されるので、リビルドする
- 指定しランタイムで、Codespaceが再起動する

![start-codespace](/images/codespace-leftbottom.png)

![start-codespace](/images/add-dev-container-config.png)


※ 指定が反映されていない場合は、リポジトリページからCodespaceを削除し、改めて作成すると反映される





## リポジトリページからの設定






# シークレット情報の設定


# 終わりに

