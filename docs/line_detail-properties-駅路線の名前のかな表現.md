## name\_kanaの型定義

`string` ([駅・路線の名前のかな表現](line_detail-properties-駅路線の名前のかな表現.md))

## name\_kanaの値の制限

**pattern**: 次の正規表現にマッチする文字列です

```regexp
^[\p{sc=Hiragana}ー・\p{gc=P}\s]+$
```

[正規表現を試す(別サイト)](https://regexr.com/?expression=%5E%5B%5Cp%7Bsc%3DHiragana%7D%E3%83%BC%E3%83%BB%5Cp%7Bgc%3DP%7D%5Cs%5D%2B%24 "try regular expression with regexr.com")

## name\_kanaの値の例

```json
"はこだて"
```

```json
"ふくしま"
```

```json
"じぇいあーるはこだてほんせん"
```
