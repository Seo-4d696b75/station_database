## itemsの型定義

`object` ([探索部分木の頂点](tree_segment-properties-頂点リスト-探索部分木の頂点.md))

# itemsのプロパティ

| Property                         | Type      | Required | Nullable | Defined by                                                                                                                                |
| :------------------------------- | :-------- | :------- | :------- | :---------------------------------------------------------------------------------------------------------------------------------------- |
| [code](#code)                    | `integer` | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅コード.md "undefined#/properties/node_list/items/properties/code")                |
| [id](#id)                        | `string`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線id.md "undefined#/properties/node_list/items/properties/id")                 |
| [name](#name)                    | `string`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線の名前.md "undefined#/properties/node_list/items/properties/name")              |
| [original\_name](#original_name) | `string`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-オリジナルの駅名称.md "undefined#/properties/node_list/items/properties/original_name")  |
| [name\_kana](#name_kana)         | `string`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線の名前のかな表現.md "undefined#/properties/node_list/items/properties/name_kana")    |
| [closed](#closed)                | `boolean` | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-廃駅フラグ.md "undefined#/properties/node_list/items/properties/closed")             |
| [lat](#lat)                      | `number`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅座標緯度.md "undefined#/properties/node_list/items/properties/lat")                |
| [lng](#lng)                      | `number`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅座標経度.md "undefined#/properties/node_list/items/properties/lng")                |
| [left](#left)                    | `integer` | Optional | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-子頂点の駅コードleft.md "undefined#/properties/node_list/items/properties/left")        |
| [right](#right)                  | `integer` | Optional | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-子頂点の駅コードright.md "undefined#/properties/node_list/items/properties/right")      |
| [segment](#segment)              | `string`  | Optional | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-部分木の名前.md "undefined#/properties/node_list/items/properties/segment")           |
| [prefecture](#prefecture)        | `integer` | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-都道府県コード.md "undefined#/properties/node_list/items/properties/prefecture")       |
| [lines](#lines)                  | `array`   | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅が登録されている路線.md "undefined#/properties/node_list/items/properties/lines")        |
| [attr](#attr)                    | `string`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の属性.md "undefined#/properties/node_list/items/properties/attr")                |
| [postal\_code](#postal_code)     | `string`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の所在地を表す郵便番号.md "undefined#/properties/node_list/items/properties/postal_code") |
| [address](#address)              | `string`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の所在地の住所.md "undefined#/properties/node_list/items/properties/address")         |
| [open\_date](#open_date)         | `string`  | Optional | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の開業日.md "undefined#/properties/node_list/items/properties/open_date")          |
| [closed\_date](#closed_date)     | `string`  | Optional | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の廃止日.md "undefined#/properties/node_list/items/properties/closed_date")        |
| [voronoi](#voronoi)              | `object`  | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲.md "undefined#/properties/node_list/items/properties/voronoi")           |

## code

データセット内の駅を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません.

`code`

*   undefinedを許可しません

*   Type: `integer` ([駅コード](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅コード.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅コード.md "undefined#/properties/node_list/items/properties/code")

### codeの型定義

`integer` ([駅コード](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅コード.md))

### codeの値の制限

**maximum**: この数値の最大値を指定します value <= `9999999`

**minimum**: この数値の最小値を指定します value >= `100000`

### codeの値の例

```json
1110101
```

```json
100409
```

## id

データセット内の駅と路線を一意に区別する値. 駅コードや路線コードとは異なり、別バージョンのデータセット間でも一貫性を保証します（駅メモ実装における「同じ」駅・路線のIDは異なるデータセットでも同じIDになります）.

`id`

*   undefinedを許可しません

*   Type: `string` ([駅・路線ID](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線id.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線id.md "undefined#/properties/node_list/items/properties/id")

### idの型定義

`string` ([駅・路線ID](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線id.md))

### idの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
^[0-9a-f]{6}$
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5E%5B0-9a-f%5D%7B6%7D%24 "try regular expression with regexr.com")

### idの値の例

```json
"d8aab0"
```

```json
"e16e64"
```

## name

駅メモに実装されているのと同じ名称です. データセット内で重複はありません. 重複防止の接尾語が付加される場合があります.

`name`

*   undefinedを許可しません

*   Type: `string` ([駅・路線の名前](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線の名前.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線の名前.md "undefined#/properties/node_list/items/properties/name")

### nameの型定義

`string` ([駅・路線の名前](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線の名前.md))

### nameの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

### nameの値の例

```json
"函館"
```

```json
"福島(福島)"
```

```json
"JR函館本線(函館～長万部)"
```

## original\_name

原則として各鉄道会社が示すままの駅名と同じ値です. nameとは異なり重複防止の接尾語を含みません.

`original_name`

*   undefinedを許可しません

*   Type: `string` ([オリジナルの駅名称](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-オリジナルの駅名称.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-オリジナルの駅名称.md "undefined#/properties/node_list/items/properties/original_name")

### original\_nameの型定義

`string` ([オリジナルの駅名称](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-オリジナルの駅名称.md))

### original\_nameの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

### original\_nameの値の例

```json
"函館"
```

```json
"福島"
```

## name\_kana

駅メモに実装されているのと同じ名称です. ひらがな以外に一部記号を含む場合があります.

`name_kana`

*   undefinedを許可しません

*   Type: `string` ([駅・路線の名前のかな表現](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線の名前のかな表現.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線の名前のかな表現.md "undefined#/properties/node_list/items/properties/name_kana")

### name\_kanaの型定義

`string` ([駅・路線の名前のかな表現](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅路線の名前のかな表現.md))

### name\_kanaの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
^[\p{sc=Hiragana}ー・\p{gc=P}\s]+$
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5E%5B%5Cp%7Bsc%3DHiragana%7D%E3%83%BC%E3%83%BB%5Cp%7Bgc%3DP%7D%5Cs%5D%2B%24 "try regular expression with regexr.com")

### name\_kanaの値の例

```json
"はこだて"
```

```json
"ふくしま"
```

```json
"じぇいあーるはこだてほんせん"
```

## closed

true: 廃駅, false: 現役駅 'main'データセットの一部では省略されます. 'undefined'の場合はfalseとして扱います.

`closed`

*   undefinedを許可しません

*   Type: `boolean` ([廃駅フラグ](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-廃駅フラグ.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-廃駅フラグ.md "undefined#/properties/node_list/items/properties/closed")

### closedの型定義

`boolean` ([廃駅フラグ](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-廃駅フラグ.md))

## lat

１０進小数で表記した緯度（小数点以下６桁）

`lat`

*   undefinedを許可しません

*   Type: `number` ([駅座標（緯度）](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅座標緯度.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅座標緯度.md "undefined#/properties/node_list/items/properties/lat")

### latの型定義

`number` ([駅座標（緯度）](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅座標緯度.md))

### latの値の制限

**maximum (exclusive)**: この数値の最大値を指定します value < `45.8`

**minimum (exclusive)**: この数値の最小値を指定します value > `26`

### latの値の例

```json
41.773709
```

```json
37.754123
```

## lng

１０進小数で表記した経度（小数点以下６桁）

`lng`

*   undefinedを許可しません

*   Type: `number` ([駅座標（経度）](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅座標経度.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅座標経度.md "undefined#/properties/node_list/items/properties/lng")

### lngの型定義

`number` ([駅座標（経度）](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅座標経度.md))

### lngの値の制限

**maximum (exclusive)**: この数値の最大値を指定します value < `146.2`

**minimum (exclusive)**: この数値の最小値を指定します value > `127.5`

### lngの値の例

```json
140.726413
```

```json
140.45968
```

## left

緯度または経度の値がこの駅の座標より小さい頂点の駅コード

`left`

*   undefinedを許可します

*   Type: `integer` ([子頂点の駅コード(left)](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-子頂点の駅コードleft.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-子頂点の駅コードleft.md "undefined#/properties/node_list/items/properties/left")

### leftの型定義

`integer` ([子頂点の駅コード(left)](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-子頂点の駅コードleft.md))

### leftの値の制限

**maximum**: この数値の最大値を指定します value <= `9999999`

**minimum**: この数値の最小値を指定します value >= `100000`

### leftの値の例

```json
1110101
```

```json
100409
```

## right

緯度または経度の値がこの駅の座標より大きい頂点の駅コード

`right`

*   undefinedを許可します

*   Type: `integer` ([子頂点の駅コード(right)](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-子頂点の駅コードright.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-子頂点の駅コードright.md "undefined#/properties/node_list/items/properties/right")

### rightの型定義

`integer` ([子頂点の駅コード(right)](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-子頂点の駅コードright.md))

### rightの値の制限

**maximum**: この数値の最大値を指定します value <= `9999999`

**minimum**: この数値の最小値を指定します value >= `100000`

### rightの値の例

```json
1110101
```

```json
100409
```

## segment

segmentが定義されている場合、指定された名前の部分木がこの頂点の下に続きます.

`segment`

*   undefinedを許可します

*   Type: `string` ([部分木の名前](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-部分木の名前.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-部分木の名前.md "undefined#/properties/node_list/items/properties/segment")

### segmentの型定義

`string` ([部分木の名前](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-部分木の名前.md))

### segmentの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

## prefecture

駅が所在する都道府県を表します.都道府県コードの値は全国地方公共団体コード（JIS X 0401）に従います.

`prefecture`

*   undefinedを許可しません

*   Type: `integer` ([都道府県コード](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-都道府県コード.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-都道府県コード.md "undefined#/properties/node_list/items/properties/prefecture")

### prefectureの型定義

`integer` ([都道府県コード](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-都道府県コード.md))

### prefectureの値の制限

**maximum**: この数値の最大値を指定します value <= `47`

**minimum**: この数値の最小値を指定します value >= `1`

## lines

路線コードのリストで表現されます.各駅は必ずひとつ以上の路線に属するため、空のリストは許可しません.

`lines`

*   undefinedを許可しません

*   Type: `integer[]` ([路線コード](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅が登録されている路線-路線コード.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅が登録されている路線.md "undefined#/properties/node_list/items/properties/lines")

### linesの型定義

`integer[]` ([路線コード](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅が登録されている路線-路線コード.md))

### linesの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`

**unique items**: リストのすべての要素は互いに異なる値です. 重複は許可されません.

### linesの値の例

```json
[
  11101,
  11119
]
```

```json
[
  1004,
  11231,
  11216,
  99213,
  99215
]
```

## attr

駅メモで定義された各駅の属性値. 廃駅の場合は'unknown'.

`attr`

*   undefinedを許可しません

*   Type: `string` ([駅の属性](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の属性.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の属性.md "undefined#/properties/node_list/items/properties/attr")

### attrの型定義

`string` ([駅の属性](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の属性.md))

### attrの値の制限

**enum**: 次のいずれかひとつの値に一致します

| Value       | Explanation |
| :---------- | :---------- |
| `"eco"`     |             |
| `"heat"`    |             |
| `"cool"`    |             |
| `"unknown"` |             |

## postal\_code

駅データ.jp由来の値、もしくは駅の緯度・軽度をGoogle Geocoding APIで自動検索した最も近い地点を指します.

`postal_code`

*   undefinedを許可しません

*   Type: `string` ([駅の所在地を表す郵便番号](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の所在地を表す郵便番号.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の所在地を表す郵便番号.md "undefined#/properties/node_list/items/properties/postal_code")

### postal\_codeの型定義

`string` ([駅の所在地を表す郵便番号](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の所在地を表す郵便番号.md))

### postal\_codeの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
^[0-9]{3}-[0-9]{4}$
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5E%5B0-9%5D%7B3%7D-%5B0-9%5D%7B4%7D%24 "try regular expression with regexr.com")

### postal\_codeの値の例

```json
"040-0063"
```

```json
"960-8031"
```

## address

駅データ.jp由来の値、もしくは駅の緯度・軽度をGoogle Geocoding APIで自動検索した最も近い地点を指します. データソースの違いにより住所表現の粒度が異なる場合があります.

`address`

*   undefinedを許可しません

*   Type: `string` ([駅の所在地の住所](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の所在地の住所.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の所在地の住所.md "undefined#/properties/node_list/items/properties/address")

### addressの型定義

`string` ([駅の所在地の住所](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の所在地の住所.md))

### addressの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

### addressの値の例

```json
"北海道函館市若松町１２-１３"
```

```json
"福島市栄町"
```

## open\_date

一部の駅のみ定義されます.

`open_date`

*   undefinedを許可します

*   Type: `string` ([駅の開業日](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の開業日.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の開業日.md "undefined#/properties/node_list/items/properties/open_date")

### open\_dateの型定義

`string` ([駅の開業日](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の開業日.md))

### open\_dateの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
^[0-9]{4}-[0-9]{2}-[0-9]{2}$
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5E%5B0-9%5D%7B4%7D-%5B0-9%5D%7B2%7D-%5B0-9%5D%7B2%7D%24 "try regular expression with regexr.com")

### open\_dateの値の例

```json
"1902-12-10"
```

## closed\_date

廃駅の一部の駅のみ定義されます. 現役駅の場合は定義されません.

`closed_date`

*   undefinedを許可します

*   Type: `string` ([駅の廃止日](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の廃止日.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の廃止日.md "undefined#/properties/node_list/items/properties/closed_date")

### closed\_dateの型定義

`string` ([駅の廃止日](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-駅の廃止日.md))

### closed\_dateの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
^[0-9]{4}-[0-9]{2}-[0-9]{2}$
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5E%5B0-9%5D%7B4%7D-%5B0-9%5D%7B2%7D-%5B0-9%5D%7B2%7D%24 "try regular expression with regexr.com")

### closed\_dateの値の例

```json
"2022-03-12"
```

## voronoi

原則としてポリゴンで表現されます. ただし外周部の一部駅のボロノイ範囲は閉じていないため、ポリライン(LineString)で表現されます. JSONによる図形の表現方法は[GeoJSON](https://geojson.org/geojson-spec.html)に従います.

`voronoi`

*   undefinedを許可しません

*   Type: `object` ([ボロノイ範囲](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲.md "undefined#/properties/node_list/items/properties/voronoi")

### voronoiの型定義

`object` ([ボロノイ範囲](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲.md))

### voronoiの値の例

```json
{
  "type": "Feature",
  "geometry": {
    "type": "Polygon",
    "coordinates": [
      [
        [
          140.72591,
          41.771256
        ],
        [
          140.717527,
          41.773829
        ],
        [
          140.71735,
          41.774204
        ],
        [
          140.714999,
          41.785757
        ],
        [
          140.714787,
          41.792259
        ],
        [
          140.72972,
          41.788694
        ],
        [
          140.730562,
          41.78452
        ],
        [
          140.731074,
          41.778908
        ],
        [
          140.72591,
          41.771256
        ]
      ]
    ]
  },
  "properties": {}
}
```
