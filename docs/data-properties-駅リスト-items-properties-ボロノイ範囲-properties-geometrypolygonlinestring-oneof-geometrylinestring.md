## 1の型定義

`object` ([geometry(LineString)](data-properties-駅リスト-items-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring.md))

## 1の値の例

```json
{
  "type": "LineString",
  "coordinates": [
    [
      160,
      32.2175
    ],
    [
      145.486252,
      43.24743
    ],
    [
      145.480118,
      43.249398
    ],
    [
      145.412432,
      42.926476
    ],
    [
      145.393203,
      42.31716
    ],
    [
      145.394284,
      42.306034
    ],
    [
      145.479425,
      41.700239
    ],
    [
      146.005674,
      39.188776
    ],
    [
      149.514356,
      35.886453
    ],
    [
      150.83862,
      34.697293
    ],
    [
      151.547974,
      34.255494
    ],
    [
      160,
      29.000091
    ]
  ]
}
```

# 1のプロパティ

| Property                    | Type     | Required | Nullable | Defined by                                                                                                                                                                                                                                                         |
| :-------------------------- | :------- | :------- | :------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [type](#type)               | `string` | Required | non-null | [All-Data](data-properties-駅リスト-items-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-type.md "undefined#/properties/stations/items/properties/voronoi/properties/geometry/oneOf/1/properties/type")                    |
| [coordinates](#coordinates) | `array`  | Required | non-null | [All-Data](data-properties-駅リスト-items-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト.md "undefined#/properties/stations/items/properties/voronoi/properties/geometry/oneOf/1/properties/coordinates") |

## type



`type`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [All-Data](data-properties-駅リスト-items-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-type.md "undefined#/properties/stations/items/properties/voronoi/properties/geometry/oneOf/1/properties/type")

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

    1.  [経度](data-properties-駅リスト-items-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点-items-経度.md "check type definition")

    2.  [緯度](data-properties-駅リスト-items-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点-items-緯度.md "check type definition")

*   non-null

*   defined in: [All-Data](data-properties-駅リスト-items-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト.md "undefined#/properties/stations/items/properties/voronoi/properties/geometry/oneOf/1/properties/coordinates")

### coordinatesの型定義

リスト. 各要素は次のとおりです

1.  [経度](data-properties-駅リスト-items-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点-items-経度.md "check type definition")

2.  [緯度](data-properties-駅リスト-items-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring-properties-linestringの座標リスト-座標点-items-緯度.md "check type definition")

### coordinatesの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `2`

### coordinatesの値の例

```json
[
  [
    160,
    32.2175
  ],
  [
    145.486252,
    43.24743
  ],
  [
    145.480118,
    43.249398
  ],
  [
    145.412432,
    42.926476
  ],
  [
    145.393203,
    42.31716
  ],
  [
    145.394284,
    42.306034
  ],
  [
    145.479425,
    41.700239
  ],
  [
    146.005674,
    39.188776
  ],
  [
    149.514356,
    35.886453
  ],
  [
    150.83862,
    34.697293
  ],
  [
    151.547974,
    34.255494
  ],
  [
    160,
    29.000091
  ]
]
```
