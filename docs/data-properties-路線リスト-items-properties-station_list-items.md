## itemsの型定義

`object` ([Details](data-properties-路線リスト-items-properties-station_list-items.md))

# itemsのプロパティ

| Property                | Type      | Required | Nullable | Defined by                                                                                                                                                                           |
| :---------------------- | :-------- | :------- | :------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [code](#code)           | `integer` | Required | non-null | [All-Data](data-properties-路線リスト-items-properties-station_list-items-properties-駅コード.md "undefined#/properties/lines/items/properties/station_list/items/properties/code")           |
| [name](#name)           | `string`  | Required | non-null | [All-Data](data-properties-路線リスト-items-properties-station_list-items-properties-駅路線の名前.md "undefined#/properties/lines/items/properties/station_list/items/properties/name")         |
| [numbering](#numbering) | `array`   | Optional | non-null | [All-Data](data-properties-路線リスト-items-properties-station_list-items-properties-numbering.md "undefined#/properties/lines/items/properties/station_list/items/properties/numbering") |

## code

データセット内の駅を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません.

`code`

*   undefinedを許可しません

*   Type: `integer` ([駅コード](data-properties-路線リスト-items-properties-station_list-items-properties-駅コード.md))

*   non-null

*   defined in: [All-Data](data-properties-路線リスト-items-properties-station_list-items-properties-駅コード.md "undefined#/properties/lines/items/properties/station_list/items/properties/code")

### codeの型定義

`integer` ([駅コード](data-properties-路線リスト-items-properties-station_list-items-properties-駅コード.md))

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

## name

駅メモに実装されているのと同じ名称です. データセット内で重複はありません. 重複防止の接尾語が付加される場合があります.

`name`

*   undefinedを許可しません

*   Type: `string` ([駅・路線の名前](data-properties-路線リスト-items-properties-station_list-items-properties-駅路線の名前.md))

*   non-null

*   defined in: [All-Data](data-properties-路線リスト-items-properties-station_list-items-properties-駅路線の名前.md "undefined#/properties/lines/items/properties/station_list/items/properties/name")

### nameの型定義

`string` ([駅・路線の名前](data-properties-路線リスト-items-properties-station_list-items-properties-駅路線の名前.md))

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

## numbering



`numbering`

*   undefinedを許可します

*   Type: `string[]`

*   non-null

*   defined in: [All-Data](data-properties-路線リスト-items-properties-station_list-items-properties-numbering.md "undefined#/properties/lines/items/properties/station_list/items/properties/numbering")

### numberingの型定義

`string[]`

### numberingの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`
