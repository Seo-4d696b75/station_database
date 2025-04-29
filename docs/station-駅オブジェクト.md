## itemsの型定義

`object` ([駅オブジェクト](station-駅オブジェクト.md))

## itemsの値の例

```json
{
  "code": 100409,
  "id": "7bfd6b",
  "name": "福島(福島)",
  "original_name": "福島",
  "name_kana": "ふくしま",
  "closed": false,
  "lat": 37.754123,
  "lng": 140.45968,
  "prefecture": 7,
  "lines": [
    1004,
    11231,
    11216,
    99213,
    99215
  ],
  "attr": "heat",
  "postal_code": "960-8031",
  "address": "福島市栄町",
  "voronoi": {
    "type": "Feature",
    "geometry": {
      "type": "Polygon",
      "coordinates": [
        [
          [
            140.436325,
            37.741446
          ],
          [
            140.441067,
            37.754985
          ],
          [
            140.446198,
            37.756742
          ],
          [
            140.501679,
            37.758667
          ],
          [
            140.510809,
            37.752683
          ],
          [
            140.527108,
            37.739585
          ],
          [
            140.534984,
            37.729765
          ],
          [
            140.436325,
            37.741446
          ]
        ]
      ]
    },
    "properties": {}
  }
}
```

# itemsのプロパティ

| Property                         | Type      | Required | Nullable | Defined by                                                                                   |
| :------------------------------- | :-------- | :------- | :------- | :------------------------------------------------------------------------------------------- |
| [code](#code)                    | `integer` | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅コード.md "undefined#/items/properties/code")                |
| [id](#id)                        | `integer` | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅id.md "undefined#/items/properties/id")                   |
| [name](#name)                    | `string`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅路線の名前.md "undefined#/items/properties/name")              |
| [original\_name](#original_name) | `string`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-オリジナルの駅名称.md "undefined#/items/properties/original_name")  |
| [name\_kana](#name_kana)         | `string`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅路線の名前のかな表現.md "undefined#/items/properties/name_kana")    |
| [closed](#closed)                | `boolean` | Required | non-null | [駅リスト](station-駅オブジェクト-properties-廃駅フラグ.md "undefined#/items/properties/closed")             |
| [lat](#lat)                      | `number`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅座標緯度.md "undefined#/items/properties/lat")                |
| [lng](#lng)                      | `number`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅座標経度.md "undefined#/items/properties/lng")                |
| [prefecture](#prefecture)        | `integer` | Required | non-null | [駅リスト](station-駅オブジェクト-properties-都道府県コード.md "undefined#/items/properties/prefecture")       |
| [lines](#lines)                  | `array`   | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅が登録されている路線.md "undefined#/items/properties/lines")        |
| [attr](#attr)                    | `string`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅の属性.md "undefined#/items/properties/attr")                |
| [postal\_code](#postal_code)     | `string`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅の所在地を表す郵便番号.md "undefined#/items/properties/postal_code") |
| [address](#address)              | `string`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-駅の所在地の住所.md "undefined#/items/properties/address")         |
| [open\_date](#open_date)         | `string`  | Optional | non-null | [駅リスト](station-駅オブジェクト-properties-駅の開業日.md "undefined#/items/properties/open_date")          |
| [closed\_date](#closed_date)     | `string`  | Optional | non-null | [駅リスト](station-駅オブジェクト-properties-駅の廃止日.md "undefined#/items/properties/closed_date")        |
| [voronoi](#voronoi)              | `object`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-ボロノイ範囲.md "undefined#/items/properties/voronoi")           |

## code

データセット内の駅を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません.

`code`

*   undefinedを許可しません

*   Type: `integer` ([駅コード](station-駅オブジェクト-properties-駅コード.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅コード.md "undefined#/items/properties/code")

### codeの型定義

`integer` ([駅コード](station-駅オブジェクト-properties-駅コード.md))

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

駅の識別子. 駅コードとは異なり、別バージョンのデータセット間でも一貫性を保証します（駅メモ実装における「同じ」駅のIDは異なるデータセットでも同じIDになります）. IDは駅メモ公式Webサイトの「駅の思い出」ページのURL <https://ekimemo.com/database/station/{id}/activity> に対応しています. 独自追加の廃駅のIDは20000番台の連番を使用しています.

`id`

*   undefinedを許可しません

*   Type: `integer` ([駅ID](station-駅オブジェクト-properties-駅id.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅id.md "undefined#/items/properties/id")

### idの型定義

`integer` ([駅ID](station-駅オブジェクト-properties-駅id.md))

### idの値の制限

**minimum**: この数値の最小値を指定します value >= `1`

### idの値の例

```json
1
```

```json
2
```

## name

駅メモに実装されているのと同じ名称です. データセット内で重複はありません. 重複防止の接尾語が付加される場合があります.

`name`

*   undefinedを許可しません

*   Type: `string` ([駅・路線の名前](station-駅オブジェクト-properties-駅路線の名前.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅路線の名前.md "undefined#/items/properties/name")

### nameの型定義

`string` ([駅・路線の名前](station-駅オブジェクト-properties-駅路線の名前.md))

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

*   Type: `string` ([オリジナルの駅名称](station-駅オブジェクト-properties-オリジナルの駅名称.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-オリジナルの駅名称.md "undefined#/items/properties/original_name")

### original\_nameの型定義

`string` ([オリジナルの駅名称](station-駅オブジェクト-properties-オリジナルの駅名称.md))

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

*   Type: `string` ([駅・路線の名前のかな表現](station-駅オブジェクト-properties-駅路線の名前のかな表現.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅路線の名前のかな表現.md "undefined#/items/properties/name_kana")

### name\_kanaの型定義

`string` ([駅・路線の名前のかな表現](station-駅オブジェクト-properties-駅路線の名前のかな表現.md))

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

*   Type: `boolean` ([廃駅フラグ](station-駅オブジェクト-properties-廃駅フラグ.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-廃駅フラグ.md "undefined#/items/properties/closed")

### closedの型定義

`boolean` ([廃駅フラグ](station-駅オブジェクト-properties-廃駅フラグ.md))

## lat

１０進小数で表記した緯度（小数点以下６桁）

`lat`

*   undefinedを許可しません

*   Type: `number` ([駅座標（緯度）](station-駅オブジェクト-properties-駅座標緯度.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅座標緯度.md "undefined#/items/properties/lat")

### latの型定義

`number` ([駅座標（緯度）](station-駅オブジェクト-properties-駅座標緯度.md))

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

*   Type: `number` ([駅座標（経度）](station-駅オブジェクト-properties-駅座標経度.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅座標経度.md "undefined#/items/properties/lng")

### lngの型定義

`number` ([駅座標（経度）](station-駅オブジェクト-properties-駅座標経度.md))

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

## prefecture

駅が所在する都道府県を表します.都道府県コードの値は全国地方公共団体コード（JIS X 0401）に従います.

`prefecture`

*   undefinedを許可しません

*   Type: `integer` ([都道府県コード](station-駅オブジェクト-properties-都道府県コード.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-都道府県コード.md "undefined#/items/properties/prefecture")

### prefectureの型定義

`integer` ([都道府県コード](station-駅オブジェクト-properties-都道府県コード.md))

### prefectureの値の制限

**maximum**: この数値の最大値を指定します value <= `47`

**minimum**: この数値の最小値を指定します value >= `1`

## lines

路線コードのリストで表現されます.各駅は必ずひとつ以上の路線に属するため、空のリストは許可しません.

`lines`

*   undefinedを許可しません

*   Type: `integer[]` ([路線コード](station-駅オブジェクト-properties-駅が登録されている路線-路線コード.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅が登録されている路線.md "undefined#/items/properties/lines")

### linesの型定義

`integer[]` ([路線コード](station-駅オブジェクト-properties-駅が登録されている路線-路線コード.md))

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

*   Type: `string` ([駅の属性](station-駅オブジェクト-properties-駅の属性.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅の属性.md "undefined#/items/properties/attr")

### attrの型定義

`string` ([駅の属性](station-駅オブジェクト-properties-駅の属性.md))

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

*   Type: `string` ([駅の所在地を表す郵便番号](station-駅オブジェクト-properties-駅の所在地を表す郵便番号.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅の所在地を表す郵便番号.md "undefined#/items/properties/postal_code")

### postal\_codeの型定義

`string` ([駅の所在地を表す郵便番号](station-駅オブジェクト-properties-駅の所在地を表す郵便番号.md))

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

*   Type: `string` ([駅の所在地の住所](station-駅オブジェクト-properties-駅の所在地の住所.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅の所在地の住所.md "undefined#/items/properties/address")

### addressの型定義

`string` ([駅の所在地の住所](station-駅オブジェクト-properties-駅の所在地の住所.md))

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

*   Type: `string` ([駅の開業日](station-駅オブジェクト-properties-駅の開業日.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅の開業日.md "undefined#/items/properties/open_date")

### open\_dateの型定義

`string` ([駅の開業日](station-駅オブジェクト-properties-駅の開業日.md))

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

*   Type: `string` ([駅の廃止日](station-駅オブジェクト-properties-駅の廃止日.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-駅の廃止日.md "undefined#/items/properties/closed_date")

### closed\_dateの型定義

`string` ([駅の廃止日](station-駅オブジェクト-properties-駅の廃止日.md))

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

*   Type: `object` ([ボロノイ範囲](station-駅オブジェクト-properties-ボロノイ範囲.md))

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-ボロノイ範囲.md "undefined#/items/properties/voronoi")

### voronoiの型定義

`object` ([ボロノイ範囲](station-駅オブジェクト-properties-ボロノイ範囲.md))

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
