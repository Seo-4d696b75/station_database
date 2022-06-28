## polyline\_listの型定義

`object` ([路線ポリライン](line_detail-properties-路線ポリライン.md))

# polyline\_listのプロパティ

| Property                  | Type     | Required | Nullable | Defined by                                                                                                                         |
| :------------------------ | :------- | :------- | :------- | :--------------------------------------------------------------------------------------------------------------------------------- |
| [type](#type)             | `string` | Required | non-null | [路線詳細オブジェクト](line_detail-properties-路線ポリライン-properties-type.md "undefined#/properties/polyline_list/properties/type")              |
| [features](#features)     | `array`  | Required | non-null | [路線詳細オブジェクト](line_detail-properties-路線ポリライン-properties-features.md "undefined#/properties/polyline_list/properties/features")      |
| [properties](#properties) | `object` | Required | non-null | [路線詳細オブジェクト](line_detail-properties-路線ポリライン-properties-路線ポリライン付加情報.md "undefined#/properties/polyline_list/properties/properties") |

## type



`type`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-路線ポリライン-properties-type.md "undefined#/properties/polyline_list/properties/type")

### typeの型定義

`string`

### typeの値の制限

**constant**: 次の値と完全に一致します

```json
"FeatureCollection"
```

## features



`features`

*   undefinedを許可しません

*   Type: `object[]` ([Details](line_detail-properties-路線ポリライン-properties-features-items.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-路線ポリライン-properties-features.md "undefined#/properties/polyline_list/properties/features")

### featuresの型定義

`object[]` ([Details](line_detail-properties-路線ポリライン-properties-features-items.md))

### featuresの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`

## properties

north, south, east, westでポイライン全体の範囲を示します.

`properties`

*   undefinedを許可しません

*   Type: `object` ([路線ポリライン付加情報](line_detail-properties-路線ポリライン-properties-路線ポリライン付加情報.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-路線ポリライン-properties-路線ポリライン付加情報.md "undefined#/properties/polyline_list/properties/properties")

### propertiesの型定義

`object` ([路線ポリライン付加情報](line_detail-properties-路線ポリライン-properties-路線ポリライン付加情報.md))
