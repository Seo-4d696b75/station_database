## voronoiの型定義

`object` ([ボロノイ範囲](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲.md))

## voronoiの値の例

```json
{
  "type": "Feature",
  "geometry": {
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
  },
  "properties": {}
}
```

# voronoiのプロパティ

| Property                  | Type     | Required | Nullable | Defined by                                                                                                                                                                               |
| :------------------------ | :------- | :------- | :------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [type](#type)             | `string` | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-type.md "undefined#/properties/node_list/items/properties/voronoi/properties/type")                          |
| [geometry](#geometry)     | Merged   | Optional | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md "undefined#/properties/node_list/items/properties/voronoi/properties/geometry") |
| [properties](#properties) | `object` | Required | non-null | [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-featureのプロパティ.md "undefined#/properties/node_list/items/properties/voronoi/properties/properties")           |

## type



`type`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-type.md "undefined#/properties/node_list/items/properties/voronoi/properties/type")

### typeの型定義

`string`

### typeの値の制限

**constant**: 次の値と完全に一致します

```json
"Feature"
```

## geometry



`geometry`

*   undefinedを許可します

*   Type: `object` ([geometry(Polygon/LineString)](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md "undefined#/properties/node_list/items/properties/voronoi/properties/geometry")

### geometryの型定義

`object` ([geometry(Polygon/LineString)](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md))

次のいずれかひとつに一致します

*   [geometry(Polygon)](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon.md "check type definition")

*   [geometry(LineString)](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring.md "check type definition")

## properties

空のオブジェクトです

`properties`

*   undefinedを許可しません

*   Type: `object` ([Featureのプロパティ](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-featureのプロパティ.md))

*   non-null

*   defined in: [探索部分木](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-featureのプロパティ.md "undefined#/properties/node_list/items/properties/voronoi/properties/properties")

### propertiesの型定義

`object` ([Featureのプロパティ](tree_segment-properties-頂点リスト-探索部分木の頂点-properties-ボロノイ範囲-properties-featureのプロパティ.md))

### propertiesの値の制限

**constant**: 次の値と完全に一致します

```json
{}
```
