# データベース管理手引き


## データファイル
`src`ディレクトリ以下

- station.csv 駅情報
- line.csv 路線情報 
- register.csv 路線-駅の登録情報


## 基本データの確認

**入力**
- station.csv 駅情報
- line.csv 路線情報
- check/line.csv 路線の登録駅数（駅メモ）
- check/prefecture.csv 都道府県情報（駅メモでの駅数）
- details/line/*.json 路線詳細（登録駅リスト）

**出力**
- station.csv 欠損値の補填  
    - 新規追加された駅・路線要素に対してIDの振り分け
    - 座標->住所の検索
    - それ以外の欠損は許容しない
- register.csv 路線の登録駅情報
- solved/station.json 駅メモ駅一覧
- solved/line.json 駅メモ路線一覧

### extra-update
```
$ ruby src/script/check.rb
```

### update
`extra-update`ブランチから対象データを持ってくる  
**注意** `merge`すると`out`ディレクトリ以下のファイルがコンフリクトする
```
$ ./src/script/checkout.bat
$ ruby src/script/check.rb --impl
```

### 確認項目
- `code`,`id`の重複なし
- `id`の新規振り分け
- 路線ごとの登録駅数の整合
- 駅・路線名の重複なし（駅メモ）
- 都道府県の駅数の整合（駅メモ）
- 廃駅と駅属性の整合（駅メモ）



## 駅のボロノイ図・Kd-tree

`src/solved/station.json`を入力としてjavaで計算  

```
src/script/diagram.bat
```

`src/diagram/station.json`に出力される


## データ統合


**入力**
- solved/station.json 駅メモ駅一覧
- solved/line.json 駅メモ路線一覧
- details/line/*.json 路線詳細
- polyline/solved/*.json 路線ポリライン
```
ruby src/script/process.rb [version]
```

`./out`に出力

## GitHub

### push

`update`ブランチで作業したら、

```
git push origin update
```

GitHub Actions で`format-test`が走る

### merge

`master` <= `update` にpull-requestを出す  
GitHub Actions で`consistency-test`が走る

### release

バージョンに対応したタグを追加する
```
git tag -a "v${version_code}"
git push origin "v${version_code}"
```

GitHub Actions で`release`が走り、`latest_info.json`の更新とリリースのドラフトが発行される。最後に手動でリリースをpublishする。