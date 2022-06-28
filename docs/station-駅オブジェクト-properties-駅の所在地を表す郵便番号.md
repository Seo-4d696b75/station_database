## postal\_codeの型定義

`string` ([駅の所在地を表す郵便番号](station-駅オブジェクト-properties-駅の所在地を表す郵便番号.md))

## postal\_codeの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
[0-9]{3}-[0-9]{4}
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5B0-9%5D%7B3%7D-%5B0-9%5D%7B4%7D "try regular expression with regexr.com")

## postal\_codeの値の例

```json
"040-0063"
```

```json
"960-8031"
```
