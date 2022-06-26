## 0の型定義

`object` ([geometry(Polygon)](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon.md))

# 0の属性

| Property                    | Type     | Required | Nullable | Defined by                                                                                                                                                                                                     |
| :-------------------------- | :------- | :------- | :------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [type](#type)               | `string` | Required | non-null | [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-type.md "undefined#/properties/voronoi/properties/geometry/oneOf/0/properties/type")                 |
| [coordinates](#coordinates) | `array`  | Required | non-null | [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト.md "undefined#/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates") |

## type



`type`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-type.md "undefined#/properties/voronoi/properties/geometry/oneOf/0/properties/type")

### typeの型定義

`string`

### typeの値の制限

**constant**: 次の値と完全に一致します

```json
"Polygon"
```

## coordinates

ボロノイ範囲は中空のないポリゴンのため、長さ１のリスト

`coordinates`

*   undefinedを許可しません

*   Type: リスト. 各要素は次のとおりです

    1.  [経度](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点-items-経度.md "check type definition")

    2.  [緯度](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点-items-緯度.md "check type definition")

*   non-null

*   defined in: [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト.md "undefined#/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates")

### coordinatesの型定義

リスト. 各要素は次のとおりです

1.  [経度](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点-items-経度.md "check type definition")

2.  [緯度](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点-items-緯度.md "check type definition")

### coordinatesの値の制限

**maximum number of items**: リストの長さの最大値を指定します value.length <= `1`

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`
