# データベース管理手引き

**編集するデータ**
- station.csv 駅情報
- line.csv 路線情報
- check/line.csv 路線の登録駅数（駅メモ）
- check/prefecture.csv 都道府県情報（駅メモでの駅数）
- details/line/*.json 路線詳細（登録駅リスト）
- polyline/raw/*.json 路線ポリライン

**build作業**
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


# build作業の詳細

## 基本データの確認

**入力**
- station.csv 駅情報
- line.csv 路線情報
- check/line.csv 路線の登録駅数（駅メモ）
- check/prefecture.csv 都道府県情報（駅メモでの駅数）
- details/line/*.json 路線詳細（登録駅リスト）

**出力**
- ${dst}/station.csv 欠損値の補填  
    - 新規追加された駅・路線要素に対してIDの振り分け
    - 座標->住所の検索
    - それ以外の欠損は許容しない
- ${dst}/line.csv
- ${dst}/register.csv 路線の登録駅情報
- src/solved/station.json 駅メモ駅一覧
- src/solved/line.json 駅メモ路線一覧

```
$ ./src/check.bat -d ${dst} [-i]
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
$ ./src/diagram.bat
```

`src/diagram/station.json`に出力される

## 路線のポリラインデータ

`solved/line.json`を基に`polyline/raw/*.json`=>`polyline/solved/*.json`に出力する

```
ruby src/script/polyline.rb
```

## データ統合


**入力**
- solved/station.json 駅メモ駅一覧
- solved/line.json 駅メモ路線一覧
- details/line/*.json 路線詳細
- polyline/solved/*.json 路線ポリライン

```
$ ./src/pack.bat -v ${version} -d ${dst} [-i]
```

`${dst}`に出力

## バージョン情報の更新

${dst}に出力

```
$ ./src/release.bat -v ${version} -s ${src} -d ${dst}
```