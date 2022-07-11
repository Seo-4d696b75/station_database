## 探索木の型定義

`object` ([探索木](tree.md))

# 探索木のプロパティ

| Property                 | Type      | Required | Nullable | Defined by                                                        |
| :----------------------- | :-------- | :------- | :------- | :---------------------------------------------------------------- |
| [root](#root)            | `integer` | Required | non-null | [探索木](tree-properties-ルート駅コード.md "undefined#/properties/root")    |
| [node\_list](#node_list) | `array`   | Required | non-null | [探索木](tree-properties-頂点リスト.md "undefined#/properties/node_list") |

## root

kd-treeのルートに位置する頂点の駅コード. node\_listに該当する頂点（駅）が必ず含まれます.

`root`

*   undefinedを許可しません

*   Type: `integer` ([ルート駅コード](tree-properties-ルート駅コード.md))

*   non-null

*   defined in: [探索木](tree-properties-ルート駅コード.md "undefined#/properties/root")

### rootの型定義

`integer` ([ルート駅コード](tree-properties-ルート駅コード.md))

## node\_list

kd-treeを構成する頂点（駅）のリスト

`node_list`

*   undefinedを許可しません

*   Type: `object[]` ([探索木の頂点](tree-properties-頂点リスト-探索木の頂点.md))

*   non-null

*   defined in: [探索木](tree-properties-頂点リスト.md "undefined#/properties/node_list")

### node\_listの型定義

`object[]` ([探索木の頂点](tree-properties-頂点リスト-探索木の頂点.md))

### node\_listの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`
