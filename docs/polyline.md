## 路線ポリラインの型定義

`object` ([路線ポリライン](polyline.md))

# 路線ポリラインのプロパティ

| Property                  | Type     | Required | Nullable | Defined by                                                                       |
| :------------------------ | :------- | :------- | :------- | :------------------------------------------------------------------------------- |
| [type](#type)             | `string` | Required | non-null | [路線ポリライン](polyline-properties-type.md "undefined#/properties/type")              |
| [features](#features)     | `array`  | Required | non-null | [路線ポリライン](polyline-properties-features.md "undefined#/properties/features")      |
| [properties](#properties) | `object` | Required | non-null | [路線ポリライン](polyline-properties-路線ポリライン付加情報.md "undefined#/properties/properties") |

## type



`type`

*   undefinedを許可しません

*   Type: `string`

*   non-null

*   defined in: [路線ポリライン](polyline-properties-type.md "undefined#/properties/type")

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

*   Type: `object[]` ([Details](polyline-properties-features-items.md))

*   non-null

*   defined in: [路線ポリライン](polyline-properties-features.md "undefined#/properties/features")

### featuresの型定義

`object[]` ([Details](polyline-properties-features-items.md))

### featuresの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`

## properties

north, south, east, westでポイライン全体の範囲を示します.

`properties`

*   undefinedを許可しません

*   Type: `object` ([路線ポリライン付加情報](polyline-properties-路線ポリライン付加情報.md))

*   non-null

*   defined in: [路線ポリライン](polyline-properties-路線ポリライン付加情報.md "undefined#/properties/properties")

### propertiesの型定義

`object` ([路線ポリライン付加情報](polyline-properties-路線ポリライン付加情報.md))
