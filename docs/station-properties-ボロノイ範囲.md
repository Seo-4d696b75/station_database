## voronoiの型定義

`object` ([ボロノイ範囲](station-properties-ボロノイ範囲.md))

# voronoiの属性

| Property                  | Type     | Required | Nullable | Defined by                                                                                                                       |
| :------------------------ | :------- | :------- | :------- | :------------------------------------------------------------------------------------------------------------------------------- |
| [type](#type)             | `string` | Required | non-null | [駅オブジェクト](station-properties-ボロノイ範囲-properties-type.md "undefined#/properties/voronoi/properties/type")                          |
| [geometry](#geometry)     | Merged   | Optional | non-null | [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md "undefined#/properties/voronoi/properties/geometry") |
| [properties](#properties) | `object` | Required | non-null | [駅オブジェクト](station-properties-ボロノイ範囲-properties-featureのプロパティ.md "undefined#/properties/voronoi/properties/properties")           |

## type



`type`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [駅オブジェクト](station-properties-ボロノイ範囲-properties-type.md "undefined#/properties/voronoi/properties/type")

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

*   Type: `object` ([geometry(Polygon/LineString)](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md "undefined#/properties/voronoi/properties/geometry")

### geometryの型定義

`object` ([geometry(Polygon/LineString)](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring.md))

次のいずれかひとつに一致します

*   [geometry(Polygon)](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrypolygon.md "check type definition")

*   [geometry(LineString)](station-properties-ボロノイ範囲-properties-geometrypolygonlinestring-oneof-geometrylinestring.md "check type definition")

## properties

空のオブジェクトです

`properties`

*   undefinedを許可しません

*   Type: `object` ([Featureのプロパティ](station-properties-ボロノイ範囲-properties-featureのプロパティ.md))

*   non-null

*   defined in: [駅オブジェクト](station-properties-ボロノイ範囲-properties-featureのプロパティ.md "undefined#/properties/voronoi/properties/properties")

### propertiesの型定義

`object` ([Featureのプロパティ](station-properties-ボロノイ範囲-properties-featureのプロパティ.md))

### propertiesの値の制限

**constant**: 次の値と完全に一致します

```json
{}
```
