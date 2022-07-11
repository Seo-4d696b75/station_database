## linesの型定義

`integer[]` ([路線コード](station-駅オブジェクト-properties-駅が登録されている路線-路線コード.md))

## linesの値の制限

**minimum number of items**: リストの長さの最小値を指定します value.length >= `1`

**unique items**: リストのすべての要素は互いに異なる値です. 重複は許可されません.

## linesの値の例

```json
[
  11101,
  11119
]
```

```json
[
  1004,
  11231,
  11216,
  99213,
  99215
]
```
