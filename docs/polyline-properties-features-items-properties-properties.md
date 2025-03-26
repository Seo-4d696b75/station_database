## propertiesの型定義

`object` ([Details](polyline-properties-features-items-properties-properties.md))

# propertiesのプロパティ

| Property        | Type     | Required | Nullable | Defined by                                                                                                                                                                  |
| :-------------- | :------- | :------- | :------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [start](#start) | `string` | Required | non-null | [路線ポリライン](polyline-properties-features-items-properties-properties-properties-ポリライン始点の識別子.md "undefined#/properties/features/items/properties/properties/properties/start") |
| [end](#end)     | `string` | Required | non-null | [路線ポリライン](polyline-properties-features-items-properties-properties-properties-ポリライン終点の識別子.md "undefined#/properties/features/items/properties/properties/properties/end")   |

## start

同じ識別子をもつポイライン末端との接続を表現します

`start`

*   undefinedを許可しません

*   Type: `string` ([ポリライン始点の識別子](polyline-properties-features-items-properties-properties-properties-ポリライン始点の識別子.md))

*   non-null

*   defined in: [路線ポリライン](polyline-properties-features-items-properties-properties-properties-ポリライン始点の識別子.md "undefined#/properties/features/items/properties/properties/properties/start")

### startの型定義

`string` ([ポリライン始点の識別子](polyline-properties-features-items-properties-properties-properties-ポリライン始点の識別子.md))

### startの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

## end

同じ識別子をもつポイライン始端との接続を表現します

`end`

*   undefinedを許可しません

*   Type: `string` ([ポリライン終点の識別子](polyline-properties-features-items-properties-properties-properties-ポリライン終点の識別子.md))

*   non-null

*   defined in: [路線ポリライン](polyline-properties-features-items-properties-properties-properties-ポリライン終点の識別子.md "undefined#/properties/features/items/properties/properties/properties/end")

### endの型定義

`string` ([ポリライン終点の識別子](polyline-properties-features-items-properties-properties-properties-ポリライン終点の識別子.md))

### endの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`
