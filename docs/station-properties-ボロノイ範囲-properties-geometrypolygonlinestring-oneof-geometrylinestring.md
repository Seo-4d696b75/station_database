## 1の型定義

`object` ([geometry(LineString)](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring.md))

# 1の属性

| Property                    | Type     | Required | Nullable | Defined by                                                                                                                                                                                                           |
| :-------------------------- | :------- | :------- | :------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [type](#type)               | `string` | Required | non-null | [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-type.md "undefined#/properties/voronoi/properties/geometry/oneOf/1/properties/type")                    |
| [coordinates](#coordinates) | `array`  | Required | non-null | [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト.md "undefined#/properties/voronoi/properties/geometry/oneOf/1/properties/coordinates") |

## type



`type`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-type.md "undefined#/properties/voronoi/properties/geometry/oneOf/1/properties/type")

### typeの型定義

`string`

### typeの値の制限

**constant**: 次の値と完全に一致します

```json
"LineString"
```

## coordinates



`coordinates`

*   undefinedを許可しません

*   Type: リスト. 各要素は次のとおりです

    1.  [経度](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点-items-経度.md "check type definition")

    2.  [緯度](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点-items-緯度.md "check type definition")

*   non-null

*   defined in: [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト.md "undefined#/properties/voronoi/properties/geometry/oneOf/1/properties/coordinates")

### coordinatesの型定義

リスト. 各要素は次のとおりです

1.  [経度](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点-items-経度.md "check type definition")

2.  [緯度](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点-items-緯度.md "check type definition")

### coordinatesの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `2`
