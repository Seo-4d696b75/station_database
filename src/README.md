# データベース管理手引き

開発者向けの説明です

## Setup

### Node + TypeScript の環境構築

`nodenv`でNodeバージョンを管理しています（バージョンの定義場所：`/.node-version`）

```bash
nodenv install 
npm install

npm run ${package.jsonで定義したscript名称}
npx ts-node ${ts_file}
npx jest ${ts_test_file}
```

### API keyの用意

GCP consoleから Geocoding API が利用可能なAPI keyを取得して以下のファイルで指定します

`src/.env.local`  

```env
GOOGLE_GEOCODING_API_KEY=${API_KEY}
```

### 改行コードの統一

`LF`に統一したいので `git config core.autocrlf input` を確認

## 更新作業

### 1. 作業ブランチの用意

`feature/update-$version`

### 2. データの編集

**マスターデータ**  

- src/station.csv 駅情報
- src/line.csv 路線情報
- src/line/*.json 路線詳細（登録駅リスト）
- src/polyline/*.json 路線ポリライン

**確認データ**  

- src/check/line.csv 路線の登録駅数（駅メモ）
- src/check/prefecture.csv 都道府県情報（駅メモでの駅数）
- src/check/polyline_ignore.csv ポリライン欠損を許す路線一覧

スクリプトでデータの整合性チェック・自動補完ができます

```bash
npm run check
```

自動補完・自動修正に対応しているフィールは以下の通りです

- src/station.csv 各駅の郵便番号（postal_code）と住所（address）
- src/line/*.json 路線登録駅の駅コード・ID（コード or IDのいずれかがsrc/station.csvのマスターデータと一致している必要あり）

### 3. バージョン更新

`src/.env`の定義を更新

### 4. ビルド作業

**リモート**  

作業ブランチをpushすると[auto-build ワークフロー](../.github/workflows/build.yml)が起動して自動ビルドが実行され、ビルド成功すると差分がcommit&pushされます

**ローカル**  

基本的にはワークフローと同様にshellスクリプトを実行します

ただし図形計算にGitHub Packageを利用する関係でGitHubアカウントの認証情報が必要です

`src/diagram/credentials.properties`

```properties
username=${github_user_name}
token=${github_access_token}
```

### 5. リリース作業

ビルド完了後に`main`ブランチをbaseにPRを作成

- テストが自動起動
- PRをマージ
- 自動でtagが打たれてreleaseを作成 
- 生成されたdraftを編集・発行

## 路線のポリラインデータ

[Polyline Editor](https://seo-4d696b75.github.io/polyline-editor/)  

- `src/polyline/*.json`にデータを定義します
- ポリラインの欠損を許容する場合は`src/check/polyline_ignore.csv`に路線名を追記します

## JSONスキーマ・ドキュメンの整備

`out/**/*.json`ファイルのフォーマットをJSON schemaで厳密に表現しています。

### 1. TypeScriptの型定義

`src/ts/model/*.ts`にてTypeScriptの型でJSONフォーマットを表現し、
[ajvライブラリ](https://ajv.js.org/)でJSON schemaを定義・バリデーションを実装しています。

### 2. JSON schema の出力

`out/*/schema/*.schema.json`を生成します

```bash
npm run schema
```

### 3. ドキュメンの出力

JSON schema をもとにマークダウン形式で`docs/*.md`を出力します(mainデータセットのみ)

```bash
npm run docs
```

## 駅メモとの整合性チェック

https://ekimemo.com/database/** から取得できるデータと比較して差分を検査します. ただし全部の路線・駅（総数10000程度）のページをダウンロードするのに時間がかかるため、PRのチェックには含まれません

### ダウンロード

```bash
rm -f src/ekimemo/station/* src/ekimemo/line/*
npm run download
```

公式Webサイトで使用する駅・路線の識別子と当データベースのcodeとの対応表も出力されます

- [駅一覧](./ekimemo/station.csv)
- [路線一覧](./ekimemo/line.csv)

### テスト

以下の項目において駅メモと差分が無いか確認します

- 駅の名前
- 駅の緯度・経度
- 駅の所在都道府県
- 駅のよみがな
- 路線の登録駅・順序

```bash
npm run test-ekimemo
```
