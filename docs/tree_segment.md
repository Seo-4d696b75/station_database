## 探索部分木の型定義

`object` ([探索部分木](tree_segment.md))

# 探索部分木のプロパティ

| Property                 | Type      | Required | Nullable | Defined by                                                                  |
| :----------------------- | :-------- | :------- | :------- | :-------------------------------------------------------------------------- |
| [name](#name)            | `string`  | Required | non-null | [探索部分木](tree_segment-properties-部分木の名前.md "undefined#/properties/name")     |
| [root](#root)            | `integer` | Required | non-null | [探索部分木](tree_segment-properties-ルート駅コード.md "undefined#/properties/root")    |
| [node\_list](#node_list) | `array`   | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト.md "undefined#/properties/node_list") |

## name

部分木の名前はファイル名と一致します ${name}.json

`name`

*   undefinedを許可しません

*   Type: `string` ([部分木の名前](tree_segment-properties-部分木の名前.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-部分木の名前.md "undefined#/properties/name")

### nameの型定義

`string` ([部分木の名前](tree_segment-properties-部分木の名前.md))

### nameの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

## root

部分木のルートに位置する頂点の駅コード. node\_listに該当する頂点（駅）が必ず含まれます.

`root`

*   undefinedを許可しません

*   Type: `integer` ([ルート駅コード](tree_segment-properties-ルート駅コード.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-ルート駅コード.md "undefined#/properties/root")

### rootの型定義

`integer` ([ルート駅コード](tree_segment-properties-ルート駅コード.md))

## node\_list

部分木を構成する頂点（駅）のリスト

`node_list`

*   undefinedを許可しません

*   Type: `object[]` ([探索部分木の頂点](tree_segment-properties-頂点リスト-探索部分木の頂点.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト.md "undefined#/properties/node_list")

### node\_listの型定義

`object[]` ([探索部分木の頂点](tree_segment-properties-頂点リスト-探索部分木の頂点.md))

### node\_listの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`
