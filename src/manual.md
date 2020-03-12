# 駅情報更新の手引き

## ekidata.jp 
[ダウンロードページ](https://ekidata.jp/dl/)から3ファイルを取得  

* company*.csv
* line*.csv
* station*.csv

保存場所は`src/raw/*.csv`

## CSVデータの解析
欲しいデータだけ取り出して整形する  
`src/raw/*.csv`を対応するスクリプト`src/script/csv_*.rb`で叩く  
以降のカレントディレクトリを`src`とする  


```
ruby script/csv_*.rb [src] [dst]
```

出力先は`src/parsed/*.json`

## 駅メモ！との差分解決

### 準備

* `src/parsed/*.json`
	入力データ
* `src/solution.json`  
	解決の方法をここに記述する
* `src/previous/*s.json`
	以前のバージョンでの完成データ
* `src/check/line.csv`
	路線名と登録駅数のリスト

### 実行
スクリプト：`src/script/solve.rb`  

```irb
load('script/solve.rb')
s = Solver.new

# parsed/line.json parsed/station.json の読み込み
s.init

# solution.json による差分解決
# 全バージョンとの差分比較によるID管理
s.solve

# check/line.csv による確認
s.check

# データ書き出し
s.write
```

出力ファイル  
* `src/solved/line.json`
* `src/solved/station.json`
* `src/diff.txt`
	前バージョンと比較したとき、駅・路線要素の新規追加や名称`name`・コード`code`・`id`の差分一覧

## 駅の詳細データ

### 準備

* `solved/*.json`
	入力データ
* `api_key.txt`
	Google Geocoding APIのAPI key
* `details/station.csv`
	駅の名称かな・所在都道府県・属性のデータ一覧
* `check/prefecture.csv`
	所在都道府県ごとの駅数一覧

### 実行
```
ruby script/details.rb
```

`details/station.json`に出力される

## 駅のボロノイ図・Kd-tree

`solved/station.json`を入力としてjavaで計算  

```
script/diagram.bat
```

`diagram/station.json`に出力される

## 路線のポリラインデータ

`solved/line.json`を基に`polyline/raw/*.json`=>`polyline/solved/*.json`に出力する

```
del polyline/solved/*
script/polyline.bat
```

## データ統合

### 準備
* `solved/line.json`
	入力路線データ
* `details/line.csv`
	路線名かな
* `polyline/solved/*.json`
	路線のポリラインデータ
* `details/line/*.json`
	路線の詳細・登録駅一覧
* `details/station.json`
	入力駅データ
* `diagram/station.json`
	ボロノイ・隣接・Kd-tree情報

### 実行
```
ruby script/merge.rb [version]
```

`../out`に出力