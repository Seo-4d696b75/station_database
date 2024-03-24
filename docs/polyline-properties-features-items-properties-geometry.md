## geometryの型定義

`object` ([Details](polyline-properties-features-items-properties-geometry.md))

# geometryのプロパティ

| Property                    | Type     | Required | Nullable | Defined by                                                                                                                                                                    |
| :-------------------------- | :------- | :------- | :------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [type](#type)               | `string` | Required | non-null | [路線ポリライン](polyline-properties-features-items-properties-geometry-properties-type.md "undefined#/properties/features/items/properties/geometry/properties/type")               |
| [coordinates](#coordinates) | `array`  | Required | non-null | [路線ポリライン](polyline-properties-features-items-properties-geometry-properties-coordinates.md "undefined#/properties/features/items/properties/geometry/properties/coordinates") |

## type



`type`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [路線ポリライン](polyline-properties-features-items-properties-geometry-properties-type.md "undefined#/properties/features/items/properties/geometry/properties/type")

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

    1.  [経度](polyline-properties-features-items-properties-geometry-properties-coordinates-座標点-items-経度.md "check type definition")

    2.  [緯度](polyline-properties-features-items-properties-geometry-properties-coordinates-座標点-items-緯度.md "check type definition")

*   non-null

*   defined in: [路線ポリライン](polyline-properties-features-items-properties-geometry-properties-coordinates.md "undefined#/properties/features/items/properties/geometry/properties/coordinates")

### coordinatesの型定義

リスト. 各要素は次のとおりです

1.  [経度](polyline-properties-features-items-properties-geometry-properties-coordinates-座標点-items-経度.md "check type definition")

2.  [緯度](polyline-properties-features-items-properties-geometry-properties-coordinates-座標点-items-緯度.md "check type definition")

### coordinatesの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `2`
