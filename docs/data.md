## All-Dataの型定義

`object` ([All-Data](data.md))

# All-Dataのプロパティ

| Property                         | Type      | Required | Nullable | Defined by                                                                    |
| :------------------------------- | :-------- | :------- | :------- | :---------------------------------------------------------------------------- |
| [version](#version)              | `integer` | Required | non-null | [All-Data](data-properties-データバージョン.md "undefined#/properties/version")       |
| [stations](#stations)            | `array`   | Required | non-null | [All-Data](data-properties-駅リスト.md "undefined#/properties/stations")          |
| [lines](#lines)                  | `array`   | Required | non-null | [All-Data](data-properties-路線リスト.md "undefined#/properties/lines")            |
| [tree\_segments](#tree_segments) | `array`   | Required | non-null | [All-Data](data-properties-探索部分木リスト.md "undefined#/properties/tree_segments") |

## version

データのバージョンをpublishした日付 yyyyMMddの形式で表現します.

`version`

*   undefinedを許可しません

*   Type: `integer` ([データバージョン](data-properties-データバージョン.md))

*   non-null

*   defined in: [All-Data](data-properties-データバージョン.md "undefined#/properties/version")

### versionの型定義

`integer` ([データバージョン](data-properties-データバージョン.md))

## stations

すべての駅のリスト

`stations`

*   undefinedを許可しません

*   Type: `object[]` ([Details](data-properties-駅リスト-items.md))

*   non-null

*   defined in: [All-Data](data-properties-駅リスト.md "undefined#/properties/stations")

### stationsの型定義

`object[]` ([Details](data-properties-駅リスト-items.md))

## lines

すべての路線のリスト. 各路線の詳細データを含みます.

`lines`

*   undefinedを許可しません

*   Type: `object[]` ([Details](data-properties-路線リスト-items.md))

*   non-null

*   defined in: [All-Data](data-properties-路線リスト.md "undefined#/properties/lines")

### linesの型定義

`object[]` ([Details](data-properties-路線リスト-items.md))

## tree\_segments

すべての駅の探索木を分割したリスト.

`tree_segments`

*   undefinedを許可しません

*   Type: `object[]` ([Details](data-properties-探索部分木リスト-items.md))

*   non-null

*   defined in: [All-Data](data-properties-探索部分木リスト.md "undefined#/properties/tree_segments")

### tree\_segmentsの型定義

`object[]` ([Details](data-properties-探索部分木リスト-items.md))
