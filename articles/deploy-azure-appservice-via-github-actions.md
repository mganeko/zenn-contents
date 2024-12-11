---
title: "ハッカソで学んだGitHub ActionsでAzure App Seriveにデプロイする手順" # 記事のタイトル
emoji: "☁️" # アイキャッチとして使われる絵文字（1文字だけ）
type: "tech" # tech: 技術記事 / idea: アイデア記事
topics: ["Azure", "githubactions", "Actions"] # タグ。["markdown", "rust", "aws"]のように指定する
published: false # 公開設定（falseにすると下書き）
---

# はじめに

この記事は非公式の[Infocom Advent Calendar 2024](https://qiita.com/advent-calendar/2024/infocom)のx日目の記事です。


# やりたいこと

[前回の記事](https://zenn.dev/mganeko/articles/study-github-codespaces)に引き続き、こちらも社内ハッカソンで学んだことになります。

今回やりたいことは次の通りです。

- Azure上に、Node.jsランタイムのApp Serviceを準備
- GitHubにTypeScriptのサーバーのコードをPush
- GitHub Actionsでビルド
- App Serviceにデプロイ

こちらも勝手が分からず色々と引っかかってしまったので、備忘録を兼ねて記事にします。

# 連携の手順

### Azure側の準備

- AzureでApp Serviceを作成
- Azure App Serviceで、発行プロファイルを準備
  - 認証形式を指定
    - App Serviceの「設定」-「」-「SCM 基本認証の発行資格...」を「オン」に
  - 発行プロファイルをダウンロード
    - App Serviceの「デプロイ」-「デプロイセンター」-「発行プロファイルの管理」から、「発行プロファイルをダウンロード」
    - ※発行プロファイルの内容は、後のステップでGitHub Actionsに設定する

![start-codespace](/images/app-service-scm.png)

![start-codespace](/images/app-service-profile.png)


### GitHub Actionsの設定

- GitHubのリポジトリで、Actions用のシークレットを指定

- GitHub Actionsを作成
  - 「Deploy Node.js to Azure Web App」テンプレートを利用
  - azure-webapps-node.yml を編集
  - AppService名を指定
  
  - Actionsのシークレットを指定
  - テンプレートを利用


## コツ

- App Service側でのログの見方
- TSを利用していた → 完全にビルドしてから、nodeで実行
- ポートの指定
  - App Serviceのデフォルトは 8080
  - 変更も可能？
- 起動コマンドの指定
  - デフォルトは npm start
  - 変更も可能
- シークレットを環境変数で指定
