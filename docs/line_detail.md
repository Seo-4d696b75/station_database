## 路線詳細オブジェクトの型定義

`object` ([路線詳細オブジェクト](line_detail.md))

# 路線詳細オブジェクトのプロパティ

| Property                         | Type      | Required | Nullable | Defined by                                                                                 |
| :------------------------------- | :-------- | :------- | :------- | :----------------------------------------------------------------------------------------- |
| [code](#code)                    | `integer` | Required | non-null | [路線詳細オブジェクト](line_detail-properties-路線コード.md "undefined#/properties/code")                 |
| [id](#id)                        | `string`  | Required | non-null | [路線詳細オブジェクト](line_detail-properties-駅路線id.md "undefined#/properties/id")                   |
| [name](#name)                    | `string`  | Required | non-null | [路線詳細オブジェクト](line_detail-properties-駅路線の名前.md "undefined#/properties/name")                |
| [name\_kana](#name_kana)         | `string`  | Required | non-null | [路線詳細オブジェクト](line_detail-properties-駅路線の名前のかな表現.md "undefined#/properties/name_kana")      |
| [name\_formal](#name_formal)     | `string`  | Optional | non-null | [路線詳細オブジェクト](line_detail-properties-路線の正式名称.md "undefined#/properties/name_formal")        |
| [station\_size](#station_size)   | `integer` | Required | non-null | [路線詳細オブジェクト](line_detail-properties-登録駅数.md "undefined#/properties/station_size")          |
| [company\_code](#company_code)   | `integer` | Optional | non-null | [路線詳細オブジェクト](line_detail-properties-事業者コード.md "undefined#/properties/company_code")        |
| [closed](#closed)                | `boolean` | Required | non-null | [路線詳細オブジェクト](line_detail-properties-廃線フラグ.md "undefined#/properties/closed")               |
| [color](#color)                  | `string`  | Optional | non-null | [路線詳細オブジェクト](line_detail-properties-路線カラー.md "undefined#/properties/color")                |
| [symbol](#symbol)                | `string`  | Optional | non-null | [路線詳細オブジェクト](line_detail-properties-路線記号.md "undefined#/properties/symbol")                |
| [closed\_date](#closed_date)     | `string`  | Optional | non-null | [路線詳細オブジェクト](line_detail-properties-路線の廃止日.md "undefined#/properties/closed_date")         |
| [impl](#impl)                    | `boolean` | Optional | non-null | [路線詳細オブジェクト](line_detail-properties-駅路線が駅メモに実装されているか表現します.md "undefined#/properties/impl") |
| [station\_list](#station_list)   | `array`   | Required | non-null | [路線詳細オブジェクト](line_detail-properties-登録駅リスト.md "undefined#/properties/station_list")        |
| [polyline\_list](#polyline_list) | `object`  | Optional | non-null | [路線詳細オブジェクト](line_detail-properties-路線ポリライン.md "undefined#/properties/polyline_list")      |

## code

データセット内の路線を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません.

`code`

*   undefinedを許可しません

*   Type: `integer` ([路線コード](line_detail-properties-路線コード.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-路線コード.md "undefined#/properties/code")

### codeの型定義

`integer` ([路線コード](line_detail-properties-路線コード.md))

### codeの値の制限

**maximum**: この数値の最大値を指定します value <= `99999`

**minimum**: この数値の最小値を指定します value >= `1000`

## id

データセット内の駅と路線を一意に区別する値. 駅コードや路線コードとは異なり、別バージョンのデータセット間でも一貫性を保証します（駅メモ実装における「同じ」駅・路線のIDは異なるデータセットでも同じIDになります）.

`id`

*   undefinedを許可しません

*   Type: `string` ([駅・路線ID](line_detail-properties-駅路線id.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-駅路線id.md "undefined#/properties/id")

### idの型定義

`string` ([駅・路線ID](line_detail-properties-駅路線id.md))

### idの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
[0-9a-f]{6}
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5B0-9a-f%5D%7B6%7D "try regular expression with regexr.com")

### idの値の例

```json
"d8aab0"
```

```json
"e16e64"
```

## name

駅メモに実装されているのと同じ名称です. データセット内で重複はありません. 重複防止の接尾語が付加される場合があります.

`name`

*   undefinedを許可しません

*   Type: `string` ([駅・路線の名前](line_detail-properties-駅路線の名前.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-駅路線の名前.md "undefined#/properties/name")

### nameの型定義

`string` ([駅・路線の名前](line_detail-properties-駅路線の名前.md))

### nameの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

### nameの値の例

```json
"函館"
```

```json
"福島(福島)"
```

```json
"JR函館本線(函館～長万部)"
```

## name\_kana

駅メモに実装されているのと同じ名称です. ひらがな以外に一部記号を含む場合があります.

`name_kana`

*   undefinedを許可しません

*   Type: `string` ([駅・路線の名前のかな表現](line_detail-properties-駅路線の名前のかな表現.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-駅路線の名前のかな表現.md "undefined#/properties/name_kana")

### name\_kanaの型定義

`string` ([駅・路線の名前のかな表現](line_detail-properties-駅路線の名前のかな表現.md))

### name\_kanaの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
[\p{sc=Hiragana}ー・\p{gc=P}\s]+
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5B%5Cp%7Bsc%3DHiragana%7D%E3%83%BC%E3%83%BB%5Cp%7Bgc%3DP%7D%5Cs%5D%2B "try regular expression with regexr.com")

### name\_kanaの値の例

```json
"はこだて"
```

```json
"ふくしま"
```

```json
"じぇいあーるはこだてほんせん"
```

## name\_formal

nameと一致する場合はundefined

`name_formal`

*   undefinedを許可します

*   Type: `string` ([路線の正式名称](line_detail-properties-路線の正式名称.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-路線の正式名称.md "undefined#/properties/name_formal")

### name\_formalの型定義

`string` ([路線の正式名称](line_detail-properties-路線の正式名称.md))

### name\_formalの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

### name\_formalの値の例

```json
"JR東北本線"
```

## station\_size

かならず１駅以上登録があります

`station_size`

*   undefinedを許可しません

*   Type: `integer` ([登録駅数](line_detail-properties-登録駅数.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-登録駅数.md "undefined#/properties/station_size")

### station\_sizeの型定義

`integer` ([登録駅数](line_detail-properties-登録駅数.md))

### station\_sizeの値の制限

**minimum**: この数値の最小値を指定します value >= `1`

### station\_sizeの値の例

```json
3
```

```json
24
```

## company\_code



`company_code`

*   undefinedを許可します

*   Type: `integer` ([事業者コード](line_detail-properties-事業者コード.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-事業者コード.md "undefined#/properties/company_code")

### company\_codeの型定義

`integer` ([事業者コード](line_detail-properties-事業者コード.md))

### company\_codeの値の制限

**minimum**: この数値の最小値を指定します value >= `0`

## closed

廃線の場合はtrue

`closed`

*   undefinedを許可しません

*   Type: `boolean` ([廃線フラグ](line_detail-properties-廃線フラグ.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-廃線フラグ.md "undefined#/properties/closed")

### closedの型定義

`boolean` ([廃線フラグ](line_detail-properties-廃線フラグ.md))

## color

RGBチャネル16進数

`color`

*   undefinedを許可します

*   Type: `string` ([路線カラー](line_detail-properties-路線カラー.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-路線カラー.md "undefined#/properties/color")

### colorの型定義

`string` ([路線カラー](line_detail-properties-路線カラー.md))

### colorの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
#[0-9A-F]{6}
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%23%5B0-9A-F%5D%7B6%7D "try regular expression with regexr.com")

### colorの値の例

```json
"#F68B1E"
```

## symbol



`symbol`

*   undefinedを許可します

*   Type: `string` ([路線記号](line_detail-properties-路線記号.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-路線記号.md "undefined#/properties/symbol")

### symbolの型定義

`string` ([路線記号](line_detail-properties-路線記号.md))

### symbolの値の制限

**minimum length**: 文字列の長さの最小値を指定します value.length >= `1`

### symbolの値の例

```json
"JU"
```

## closed\_date

廃線の一部のみ定義されます. 現役駅の場合は定義されません.

`closed_date`

*   undefinedを許可します

*   Type: `string` ([路線の廃止日](line_detail-properties-路線の廃止日.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-路線の廃止日.md "undefined#/properties/closed_date")

### closed\_dateの型定義

`string` ([路線の廃止日](line_detail-properties-路線の廃止日.md))

### closed\_dateの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
[0-9]{4}-[0-9]{2}-[0-9]{2}
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5B0-9%5D%7B4%7D-%5B0-9%5D%7B2%7D-%5B0-9%5D%7B2%7D "try regular expression with regexr.com")

### closed\_dateの値の例

```json
"2015-03-14"
```

## impl

true: 駅メモに登録されています. false: 登録されていない独自追加された廃駅・廃線です. 'main'データセットの一部ではこの属性は省略され、'undefined'はtrueと同じ扱いです.

`impl`

*   undefinedを許可します

*   Type: `boolean` ([駅・路線が駅メモに実装されているか表現します](line_detail-properties-駅路線が駅メモに実装されているか表現します.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-駅路線が駅メモに実装されているか表現します.md "undefined#/properties/impl")

### implの型定義

`boolean` ([駅・路線が駅メモに実装されているか表現します](line_detail-properties-駅路線が駅メモに実装されているか表現します.md))

## station\_list

原則として駅メモ実装と同じ順序です

`station_list`

*   undefinedを許可しません

*   Type: `object[]` ([駅オブジェクト(路線登録)](line_detail-properties-登録駅リスト-駅オブジェクト路線登録.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-登録駅リスト.md "undefined#/properties/station_list")

### station\_listの型定義

`object[]` ([駅オブジェクト(路線登録)](line_detail-properties-登録駅リスト-駅オブジェクト路線登録.md))

### station\_listの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`

## polyline\_list

Feature(LineString)で表現されるポリラインの集合FeatureCollectionです. フォーマットの詳細はGeoJSONに従います.

`polyline_list`

*   undefinedを許可します

*   Type: `object` ([路線ポリライン](line_detail-properties-路線ポリライン.md))

*   non-null

*   defined in: [路線詳細オブジェクト](line_detail-properties-路線ポリライン.md "undefined#/properties/polyline_list")

### polyline\_listの型定義

`object` ([路線ポリライン](line_detail-properties-路線ポリライン.md))
