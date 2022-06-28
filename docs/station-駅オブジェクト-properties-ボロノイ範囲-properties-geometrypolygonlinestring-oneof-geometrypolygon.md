## 0の型定義

`object` ([geometry(Polygon)](station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon.md))

## 0の値の例

```json
{
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
}
```

# 0の属性

| Property                    | Type     | Required | Nullable | Defined by                                                                                                                                                                                                                |
| :-------------------------- | :------- | :------- | :------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [type](#type)               | `string` | Required | non-null | [駅リスト](station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-type.md "undefined#/items/properties/voronoi/properties/geometry/oneOf/0/properties/type")                 |
| [coordinates](#coordinates) | `array`  | Required | non-null | [駅リスト](station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト.md "undefined#/items/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates") |

## type



`type`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-type.md "undefined#/items/properties/voronoi/properties/geometry/oneOf/0/properties/type")

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

    1.  [経度](station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点-items-経度.md "check type definition")

    2.  [緯度](station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点-items-緯度.md "check type definition")

*   non-null

*   defined in: [駅リスト](station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト.md "undefined#/items/properties/voronoi/properties/geometry/oneOf/0/properties/coordinates")

### coordinatesの型定義

リスト. 各要素は次のとおりです

1.  [経度](station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点-items-経度.md "check type definition")

2.  [緯度](station-駅オブジェクト-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon-properties-polygonの座標リスト-polygonの座標リスト0-座標点-items-緯度.md "check type definition")

### coordinatesの値の制限

**maximum number of items**: リストの長さの最大値を指定します value.length <= `1`

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`

### coordinatesの値の例

```json
[
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
```
