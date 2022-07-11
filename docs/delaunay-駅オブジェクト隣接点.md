## itemsの型定義

`object` ([駅オブジェクト(隣接点)](delaunay-駅オブジェクト隣接点.md))

# itemsのプロパティ

| Property      | Type      | Required | Nullable | Defined by                                                                               |
| :------------ | :-------- | :------- | :------- | :--------------------------------------------------------------------------------------- |
| [code](#code) | `integer` | Required | non-null | [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-駅コード.md "undefined#/items/properties/code")      |
| [name](#name) | `string`  | Required | non-null | [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-駅路線の名前.md "undefined#/items/properties/name")    |
| [lat](#lat)   | `number`  | Required | non-null | [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-駅座標緯度.md "undefined#/items/properties/lat")      |
| [lng](#lng)   | `number`  | Required | non-null | [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-駅座標経度.md "undefined#/items/properties/lng")      |
| [next](#next) | `array`   | Required | non-null | [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-隣接駅コードリスト.md "undefined#/items/properties/next") |

## code

データセット内の駅を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません.

`code`

*   undefinedを許可しません

*   Type: `integer` ([駅コード](delaunay-駅オブジェクト隣接点-properties-駅コード.md))

*   non-null

*   defined in: [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-駅コード.md "undefined#/items/properties/code")

### codeの型定義

`integer` ([駅コード](delaunay-駅オブジェクト隣接点-properties-駅コード.md))

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

*   Type: `string` ([駅・路線の名前](delaunay-駅オブジェクト隣接点-properties-駅路線の名前.md))

*   non-null

*   defined in: [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-駅路線の名前.md "undefined#/items/properties/name")

### nameの型定義

`string` ([駅・路線の名前](delaunay-駅オブジェクト隣接点-properties-駅路線の名前.md))

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

## lat

１０進小数で表記した緯度（小数点以下６桁）

`lat`

*   undefinedを許可しません

*   Type: `number` ([駅座標（緯度）](delaunay-駅オブジェクト隣接点-properties-駅座標緯度.md))

*   non-null

*   defined in: [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-駅座標緯度.md "undefined#/items/properties/lat")

### latの型定義

`number` ([駅座標（緯度）](delaunay-駅オブジェクト隣接点-properties-駅座標緯度.md))

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

*   Type: `number` ([駅座標（経度）](delaunay-駅オブジェクト隣接点-properties-駅座標経度.md))

*   non-null

*   defined in: [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-駅座標経度.md "undefined#/items/properties/lng")

### lngの型定義

`number` ([駅座標（経度）](delaunay-駅オブジェクト隣接点-properties-駅座標経度.md))

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

## next

隣接駅の駅コードを要素に持ちます.

`next`

*   undefinedを許可しません

*   Type: `integer[]` ([駅コード](delaunay-駅オブジェクト隣接点-properties-隣接駅コードリスト-駅コード.md))

*   non-null

*   defined in: [隣接点リスト](delaunay-駅オブジェクト隣接点-properties-隣接駅コードリスト.md "undefined#/items/properties/next")

### nextの型定義

`integer[]` ([駅コード](delaunay-駅オブジェクト隣接点-properties-隣接駅コードリスト-駅コード.md))

### nextの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`

**unique items**: リストのすべての要素は互いに異なる値です. 重複は許可されません.

### nextの値の例

```json
[
  9910514,
  1110102,
  9910518,
  9910622,
  9910621,
  9910515,
  9910623,
  9910517
]
```
