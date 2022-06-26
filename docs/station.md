## 駅オブジェクトの型定義

`object` ([駅オブジェクト](station.md))

# 駅オブジェクトの属性

| Property                         | Type      | Required | Nullable | Defined by                                                                          |
| :------------------------------- | :-------- | :------- | :------- | :---------------------------------------------------------------------------------- |
| [code](#code)                    | `integer` | Required | non-null | [駅オブジェクト](station-properties-駅コード.md "undefined#/properties/code")                  |
| [id](#id)                        | `string`  | Required | non-null | [駅オブジェクト](station-properties-駅路線id.md "undefined#/properties/id")                   |
| [name](#name)                    | `string`  | Required | non-null | [駅オブジェクト](station-properties-駅路線の名前.md "undefined#/properties/name")                |
| [original\_name](#original_name) | `string`  | Required | non-null | [駅オブジェクト](station-properties-オリジナルの駅名称.md "undefined#/properties/original_name")    |
| [name\_kana](#name_kana)         | `string`  | Required | non-null | [駅オブジェクト](station-properties-駅路線の名前のかな表現.md "undefined#/properties/name_kana")      |
| [closed](#closed)                | `boolean` | Required | non-null | [駅オブジェクト](station-properties-廃駅フラグ.md "undefined#/properties/closed")               |
| [lat](#lat)                      | `number`  | Required | non-null | [駅オブジェクト](station-properties-駅座標緯度.md "undefined#/properties/lat")                  |
| [lng](#lng)                      | `number`  | Required | non-null | [駅オブジェクト](station-properties-駅座標経度.md "undefined#/properties/lng")                  |
| [prefecture](#prefecture)        | `integer` | Required | non-null | [駅オブジェクト](station-properties-都道府県コード.md "undefined#/properties/prefecture")         |
| [lines](#lines)                  | `array`   | Required | non-null | [駅オブジェクト](station-properties-駅が登録されている路線.md "undefined#/properties/lines")          |
| [attr](#attr)                    | `string`  | Optional | non-null | [駅オブジェクト](station-properties-駅の属性.md "undefined#/properties/attr")                  |
| [postal\_code](#postal_code)     | `string`  | Required | non-null | [駅オブジェクト](station-properties-駅の所在地を表す郵便番号.md "undefined#/properties/postal_code")   |
| [address](#address)              | `string`  | Required | non-null | [駅オブジェクト](station-properties-駅の所在地の住所.md "undefined#/properties/address")           |
| [open\_date](#open_date)         | `string`  | Optional | non-null | [駅オブジェクト](station-properties-駅の開業日.md "undefined#/properties/open_date")            |
| [closed\_date](#closed_date)     | `string`  | Optional | non-null | [駅オブジェクト](station-properties-駅の廃止日.md "undefined#/properties/closed_date")          |
| [voronoi](#voronoi)              | `object`  | Required | non-null | [駅オブジェクト](station-properties-ボロノイ範囲.md "undefined#/properties/voronoi")             |
| [impl](#impl)                    | `boolean` | Optional | non-null | [駅オブジェクト](station-properties-駅路線が駅メモに実装されているか表現します.md "undefined#/properties/impl") |

## code

データセット内の駅を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません.

`code`

*   undefinedを許可しません

*   Type: `integer` ([駅コード](station-properties-駅コード.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅コード.md "undefined#/properties/code")

### codeの型定義

`integer` ([駅コード](station-properties-駅コード.md))

### codeの値の制限

**maximum**: この数値の最大値を指定します value <= `9999999`

**minimum**: この数値の最小値を指定します value >= `100000`

## id

データセット内の駅と路線を一意に区別する値. 駅コードや路線コードとは異なり、別バージョンのデータセット間でも一貫性を保証します（駅メモ実装における「同じ」駅・路線のIDは異なるデータセットでも同じIDになります）.

`id`

*   undefinedを許可しません

*   Type: `string` ([駅・路線ID](station-properties-駅路線id.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅路線id.md "undefined#/properties/id")

### idの型定義

`string` ([駅・路線ID](station-properties-駅路線id.md))

### idの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
[0-9a-f]{6}
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5B0-9a-f%5D%7B6%7D "try regular expression with regexr.com")

## name

駅メモに実装されているのと同じ名称です. データセット内で重複はありません. 重複防止の接尾語が付加される場合があります.

`name`

*   undefinedを許可しません

*   Type: `string` ([駅・路線の名前](station-properties-駅路線の名前.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅路線の名前.md "undefined#/properties/name")

### nameの型定義

`string` ([駅・路線の名前](station-properties-駅路線の名前.md))

### nameの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

## original\_name

原則として各鉄道会社が示すままの駅名と同じ値です. nameとは異なり重複防止の接尾語を含みません.

`original_name`

*   undefinedを許可しません

*   Type: `string` ([オリジナルの駅名称](station-properties-オリジナルの駅名称.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-オリジナルの駅名称.md "undefined#/properties/original_name")

### original\_nameの型定義

`string` ([オリジナルの駅名称](station-properties-オリジナルの駅名称.md))

### original\_nameの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

## name\_kana

駅メモに実装されているのと同じ名称です. ひらがな以外に一部記号を含む場合があります.

`name_kana`

*   undefinedを許可しません

*   Type: `string` ([駅・路線の名前のかな表現](station-properties-駅路線の名前のかな表現.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅路線の名前のかな表現.md "undefined#/properties/name_kana")

### name\_kanaの型定義

`string` ([駅・路線の名前のかな表現](station-properties-駅路線の名前のかな表現.md))

### name\_kanaの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
[\p{sc=Hiragana}ー・\p{gc=P}\s]+
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5B%5Cp%7Bsc%3DHiragana%7D%E3%83%BC%E3%83%BB%5Cp%7Bgc%3DP%7D%5Cs%5D%2B "try regular expression with regexr.com")

## closed

true: 廃駅, false: 現役駅 'main'データセットの一部では省略されます. 'undefined'の場合はfalseとして扱います.

`closed`

*   undefinedを許可しません

*   Type: `boolean` ([廃駅フラグ](station-properties-廃駅フラグ.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-廃駅フラグ.md "undefined#/properties/closed")

### closedの型定義

`boolean` ([廃駅フラグ](station-properties-廃駅フラグ.md))

## lat

１０進小数で表記した緯度

`lat`

*   undefinedを許可しません

*   Type: `number` ([駅座標（緯度）](station-properties-駅座標緯度.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅座標緯度.md "undefined#/properties/lat")

### latの型定義

`number` ([駅座標（緯度）](station-properties-駅座標緯度.md))

### latの値の制限

**maximum (exclusive)**: この数値の最大値を指定します value < `45.8`

**minimum (exclusive)**: この数値の最小値を指定します value > `26`

## lng

１０進小数で表記した経度

`lng`

*   undefinedを許可しません

*   Type: `number` ([駅座標（経度）](station-properties-駅座標経度.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅座標経度.md "undefined#/properties/lng")

### lngの型定義

`number` ([駅座標（経度）](station-properties-駅座標経度.md))

### lngの値の制限

**maximum (exclusive)**: この数値の最大値を指定します value < `146.2`

**minimum (exclusive)**: この数値の最小値を指定します value > `127.5`

## prefecture

駅が所在する都道府県を表します.都道府県コードの値は全国地方公共団体コード（JIS X 0401）に従います.

`prefecture`

*   undefinedを許可しません

*   Type: `integer` ([都道府県コード](station-properties-都道府県コード.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-都道府県コード.md "undefined#/properties/prefecture")

### prefectureの型定義

`integer` ([都道府県コード](station-properties-都道府県コード.md))

### prefectureの値の制限

**maximum**: この数値の最大値を指定します value <= `47`

**minimum**: この数値の最小値を指定します value >= `1`

## lines

路線コードのリストで表現されます.各駅は必ずひとつ以上の路線に属するため、空のリストは許可しません.

`lines`

*   undefinedを許可しません

*   Type: `integer[]` ([路線コード](station-properties-駅が登録されている路線-路線コード.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅が登録されている路線.md "undefined#/properties/lines")

### linesの型定義

`integer[]` ([路線コード](station-properties-駅が登録されている路線-路線コード.md))

### linesの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`

**unique items**: リストのすべての要素は互いに異なる値です. 重複は許可されません.

## attr

駅メモで定義された各駅の属性値. 廃駅の場合は'unknown'. 駅メモに実装されていない独自廃駅の場合は'undefined'.

`attr`

*   undefinedを許可します

*   Type: `string` ([駅の属性](station-properties-駅の属性.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅の属性.md "undefined#/properties/attr")

### attrの型定義

`string` ([駅の属性](station-properties-駅の属性.md))

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

*   Type: `string` ([駅の所在地を表す郵便番号](station-properties-駅の所在地を表す郵便番号.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅の所在地を表す郵便番号.md "undefined#/properties/postal_code")

### postal\_codeの型定義

`string` ([駅の所在地を表す郵便番号](station-properties-駅の所在地を表す郵便番号.md))

### postal\_codeの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
[0-9]{3}-[0-9]{4}
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5B0-9%5D%7B3%7D-%5B0-9%5D%7B4%7D "try regular expression with regexr.com")

## address

駅データ.jp由来の値、もしくは駅の緯度・軽度をGoogle Geocoding APIで自動検索した最も近い地点を指します. データソースの違いにより住所表現の粒度が異なる場合があります.

`address`

*   undefinedを許可しません

*   Type: `string` ([駅の所在地の住所](station-properties-駅の所在地の住所.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅の所在地の住所.md "undefined#/properties/address")

### addressの型定義

`string` ([駅の所在地の住所](station-properties-駅の所在地の住所.md))

### addressの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

## open\_date

一部の駅のみ定義されます.

`open_date`

*   undefinedを許可します

*   Type: `string` ([駅の開業日](station-properties-駅の開業日.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅の開業日.md "undefined#/properties/open_date")

### open\_dateの型定義

`string` ([駅の開業日](station-properties-駅の開業日.md))

### open\_dateの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
[0-9]{4}-[0-9]{2}-[0-9]{2}
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5B0-9%5D%7B4%7D-%5B0-9%5D%7B2%7D-%5B0-9%5D%7B2%7D "try regular expression with regexr.com")

## closed\_date

廃駅の一部の駅のみ定義されます. 現役駅の場合は定義されません.

`closed_date`

*   undefinedを許可します

*   Type: `string` ([駅の廃止日](station-properties-駅の廃止日.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅の廃止日.md "undefined#/properties/closed_date")

### closed\_dateの型定義

`string` ([駅の廃止日](station-properties-駅の廃止日.md))

### closed\_dateの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
[0-9]{4}-[0-9]{2}-[0-9]{2}
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5B0-9%5D%7B4%7D-%5B0-9%5D%7B2%7D-%5B0-9%5D%7B2%7D "try regular expression with regexr.com")

## voronoi

原則としてポリゴンで表現されます. ただし外周部の一部駅のボロノイ範囲は閉じていないため、ポリライン(LineString)で表現されます. JSONによる図形の表現方法は[GeoJSON](https://geojson.org/geojson-spec.html)に従います.

`voronoi`

*   undefinedを許可しません

*   Type: `object` ([ボロノイ範囲](station-properties-ボロノイ範囲.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-ボロノイ範囲.md "undefined#/properties/voronoi")

### voronoiの型定義

`object` ([ボロノイ範囲](station-properties-ボロノイ範囲.md))

## impl

true: 駅メモに登録されています. false: 登録されていない独自追加された廃駅・廃線です. 'main'データセットの一部ではこの属性は省略され、'undefined'はtrueと同じ扱いです.

`impl`

*   undefinedを許可します

*   Type: `boolean` ([駅・路線が駅メモに実装されているか表現します](station-properties-駅路線が駅メモに実装されているか表現します.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-駅路線が駅メモに実装されているか表現します.md "undefined#/properties/impl")

### implの型定義

`boolean` ([駅・路線が駅メモに実装されているか表現します](station-properties-駅路線が駅メモに実装されているか表現します.md))
