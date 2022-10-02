---
title: "PostDev(2022)セッションメモ-フロントエンド開発テスト最前線 " # 記事のタイトル
emoji: "📄" # アイキャッチとして使われる絵文字（1文字だけ）
type: "idea" # tech: 技術記事 / idea: アイデア記事
topics: ["frontend", "test"] # タグ。["markdown", "rust", "aws"]のように指定する
published: true # 公開設定（falseにすると下書き）
---

# はじめに

2022/10/01に開催された[PostDev](https://lp.nijibox.jp/cp/postdev/)を視聴したメモです。対象セッションはこちら

- フロントエンド開発テスト最前線 (13:30-14:20)


# フロントエンド開発テスト最前線の個人的メモ

## (1) フロントエンドテストが書かれてこなかった理由

- ロジックはテストしている
- 見た目のところはテストしなかった
  - すぐ壊れる、コスパが悪いと思われていた
  - 非同期が多く繊細、フレイキー

## (2) いまはどうなの？

- フロントエンドでもまあままテストが書けるようになってた
- ターニングポイントは？
  - フロントとサーバーの処理が分かれてきた
    - バックエンドが無くてもある程度動かせる、テスト容易性が増えてきた
  - 責任分界点が、JSONのやり取りになってきた。
    - 道が細くなったところをテストで押さえればよい
    - 並列で開発できる、スキーマを決めれば別々に作ってテストできる
  - ロジックがフロントエンドに寄って行った、テストの動機が増えた
    - コスパの面で、ペイするようになってきた
  - DOMスクリプティングの時代から、アプリをつくる時代になったから
  - React.js は、特定のプロパティ→特定のコンポーネントが返ってくる
    - HTML全体ではないので、部分部分でテストしやすくなった
  
## (3) テストはやりやすくなった？

- データ→HTMLの関数と捉えられる。in-outで確認できるのでテストしやすい
  - input(JSON)が決まれば、あるoutput(HTML)が返ってくる
- HTMLの検証コードが大変
  - 最初の結果を正とする。スナップショットテスティングが発展してきた
  - （疑問：ブラウザの挙動まではテストしない、ということ？）
- 見た目、バージョン差分もエコシステムの発展でそこまで意識しなくて良い
- 昔はAutomationで動かせるブラウザが少なかった
  - ツール類はCSSがフルで再現できなかった
- いまはヘッドレスブラウザも使える
  - バージョンも固定できる、ピクセルずれもほとんど起きない
  - ブラウザの挙動、見た目のテストも可能になってきた

## (4) ピンチポイントでデータの入力側はどう扱うのが良いか？

- msw (mock service worker) を使ったり
  - https://mswjs.io/
  - service worker でHTTPを乗っとる
- フロント側はそのままでOK
- Node.jsでも動くのでサーバーサイドでも使える

## (5) スキーマの決め方は、どうすると良い？ ツールとか

- よりどころになるスキーマがあること、約束事があること
- 共通のスキーマにより、並列で開発できる
- スキーマを書く→テストも生成するツールもある
- 本物と、テスト用の仕組みの動きが、違うことを早く発見できるか？
  - CIできるようになった
  - フロントエンドと、バックエンド側の考えの違いを早い段階で発見できる

## (6) 使っているツール、考え方

- 見た目のテスト … ストーリーブック
- regcap、 regcli ??
- 自動テストツール … 自分で用意しているツールもある
- GraphQLを使っているところが多い
  - スキーマがあるので、チェックできる
  - そうでない部分は、mswで期待を表現

## (7) フロントエンドテストの今後

- 再現性があり、比較的安定性あるテストの基盤ができた
- が、本質的には不安定
  - 環境の不安定
  - 画面がどんどん変化（進化）するから
- プロダクトの変化を、テストが疎外する事は避けたい
  - アクセシビリティを活用すると、カバーできるかも
  - アクセシビリティが高い＝テスタビリティが高い、になってきた
- テスタビリティ→アクセシビリティの流れもでてきた

# おわりに

興味深いセッション、どうもありがとうごます！



