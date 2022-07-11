## itemsの型定義

`object` ([Details](data-properties-探索部分木リスト-items.md))

# itemsのプロパティ

| Property                 | Type      | Required | Nullable | Defined by                                                                                                                          |
| :----------------------- | :-------- | :------- | :------- | :---------------------------------------------------------------------------------------------------------------------------------- |
| [name](#name)            | `string`  | Required | non-null | [All-Data](data-properties-探索部分木リスト-items-properties-name.md "undefined#/properties/tree_segments/items/properties/name")           |
| [root](#root)            | `integer` | Required | non-null | [All-Data](data-properties-探索部分木リスト-items-properties-駅コード.md "undefined#/properties/tree_segments/items/properties/root")           |
| [node\_list](#node_list) | `array`   | Required | non-null | [All-Data](data-properties-探索部分木リスト-items-properties-node_list.md "undefined#/properties/tree_segments/items/properties/node_list") |

## name



`name`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [All-Data](data-properties-探索部分木リスト-items-properties-name.md "undefined#/properties/tree_segments/items/properties/name")

### nameの型定義

`string`

### nameの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

## root

データセット内の駅を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません.

`root`

*   undefinedを許可しません

*   Type: `integer` ([駅コード](data-properties-探索部分木リスト-items-properties-駅コード.md))

*   non-null

*   defined in: [All-Data](data-properties-探索部分木リスト-items-properties-駅コード.md "undefined#/properties/tree_segments/items/properties/root")

### rootの型定義

`integer` ([駅コード](data-properties-探索部分木リスト-items-properties-駅コード.md))

### rootの値の制限

**maximum**: この数値の最大値を指定します value <= `9999999`

**minimum**: この数値の最小値を指定します value >= `100000`

### rootの値の例

```json
1110101
```

```json
100409
```

## node\_list



`node_list`

*   undefinedを許可しません

*   Type: `object[]` ([Details](data-properties-探索部分木リスト-items-properties-node_list-items.md))

*   non-null

*   defined in: [All-Data](data-properties-探索部分木リスト-items-properties-node_list.md "undefined#/properties/tree_segments/items/properties/node_list")

### node\_listの型定義

`object[]` ([Details](data-properties-探索部分木リスト-items-properties-node_list-items.md))

### node\_listの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`
