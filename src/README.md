# データベース管理手引き

開発者向けの説明です

# Setup

## Node + TypeScript の環境構築
データのバッチ処理にTypeScriptを利用しています  
明示的な型定義によりデータ定義の曖昧さを可能な限り排除しつつ、
JS譲りの高い生産性が期待できます

`nodebrew`の利用

```bash
nodebrew use v16.14.0
```

`nodenv`の利用

```bash
nodenv install 16.14.0
nodenv global 16.14.0
```

必要なパッケージの取得
```bash
npm install
```

## Gemの依存解決

rubyスクリプトで使用します

```bash
gem install dotenv
```

## API keyの用意
GCP consoleから Geocoding API が利用可能なAPI keyを取得して以下のファイルで指定します

`src/.env.local`  

```env
GOOGLE_GEOCODING_API_KEY=${API_KEY}
```

## 改行コードの統一
`LF`に統一したいので `git config core.autocrlf input` を確認

# 更新作業

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

スクリプトでデータ自動補完できます
```bash
ruby src/script/check.rb
```

### 3. バージョン更新

`src/.env`の定義を更新

### 4. ビルド作業

`main`ブランチをbaseにPRを出す

- テストが自動起動
- PRをマージ
- `auto-build`で自動ビルド

### 5. リリース作業

ビルド完了後に`main`ブランチをbaseにPRが自動作成


- テストx2が自動起動
- PRをマージ
- 自動でtagが打たれてreleaseを作成 
- 生成されたdraftを編集・発行

**注意**  
自動生成されたPRはGithubActionsのワークフローをトリガーできないので、  
- PRを一度closeしてからreopenする
- 適当なcommitをpushする



## 路線のポリラインデータ

[Polyline Editor](https://seo-4d696b75.github.io/polyline-editor/)  

`solved/line.json`を基に`polyline/raw/*.json`=>`polyline/solved/*.json`に出力する

```
ruby src/script/polyline.rb
```