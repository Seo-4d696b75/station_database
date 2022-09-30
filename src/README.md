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

`src/.env`  

```env
GOOGLE_GEOCODING_API_KEY=${API_KEY}
DIAGRAM_JAR_PATH=${PATH_TO_JAR}
```

## ボロノイ分割計算のセットアップ
[diagram](https://github.com/Seo-4d696b75/diagram)のプロジェクトをbuildしてjarファイルを用意

以下のファイルでjarファイルを指定します

`src/.env`  

```env
GOOGLE_GEOCODING_API_KEY=${API_KEY}
DIAGRAM_JAR_PATH=${PATH_TO_JAR}
```

## 改行コードの統一
`LF`に統一したいので `git config core.autocrlf input` を確認

# 更新作業

## 編集するデータ  

**マスターデータ**  
- station.csv 駅情報
- line.csv 路線情報
- details/line/*.json 路線詳細（登録駅リスト）
- polyline/raw/*.json 路線ポリライン

**確認データ**  
- check/line.csv 路線の登録駅数（駅メモ）
- check/prefecture.csv 都道府県情報（駅メモでの駅数）
- check/polyline_ignore.csv ポリライン欠損を許す路線一覧

## build作業
`./out`以下に出力

1. build & push

```
$ src/build.bat ${version}
```

2. merge PR

`main`へのPRを立てる  
もし修正が必要なら編集・1-2の作業を繰り返す

3. push tag

作業が完成したらtagを付けてpushする  
github上で対応するreleaseを自動生成する  

```
$ src/publish.bat ${version}
```

4. publish release

自動で生成されたdraftを編集・発行

## 路線のポリラインデータ

[Polyline Editor](https://seo-4d696b75.github.io/polyline-editor/)  

`solved/line.json`を基に`polyline/raw/*.json`=>`polyline/solved/*.json`に出力する

```
ruby src/script/polyline.rb
```