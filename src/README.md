# データベース管理手引き

開発者向けの説明です

# Setup

## Node + TypeScript の環境構築
データのバッチ処理にTypeScriptを利用しています

```bash
nodenv install 16.14.0
nodenv local 16.14.0
npm install
```

## Ruby(Gem)の依存解決

rubyスクリプトで使用します

```bash
rbenv install 2.7.0
rbenv local 2.7.0
gem install bundler
bundle install

bundle exec ruby ${your_ruby_script}.rb
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

スクリプトでデータ自動補完できます（オプション`-i`のインタラクションモードで実行）
```bash
bundle exec ruby src/script/check.rb -i
```

### 3. バージョン更新

`src/.env`の定義を更新

### 4. ビルド作業

作業ブランチをpushすると`auto-build`ワークフローが起動して自動ビルド  
ビルド成功すると差分がcommit&pushされる

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
