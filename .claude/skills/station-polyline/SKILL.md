---
name: station-polyline
description: 路線ポリラインデータ（src/polyline/{code}.json と out/*/polyline/{code}.json）の確認・編集・検証の手引き。路線の線形・座標・セグメント・ポリライン欠損・ポリライン範囲外エラー・Polyline Editor に関する作業や質問のときに使う。
---

# 路線ポリライン

路線の線形を表す座標データ。マスターデータ（独自形式）を編集し、ビルドで GeoJSON に変換される。

## ファイルと路線コード

| 種類 | パス | 形式 |
|:--|:--|:--|
| マスターデータ | `src/polyline/{code}.json` | 独自形式 → [references/polyline-src.schema.json](references/polyline-src.schema.json) |
| 成果物 | `out/main/polyline/{code}.json`, `out/extra/polyline/{code}.json` | GeoJSON → `out/main/schema/polyline.schema.json` |

- `{code}` は路線コード。`src/line.csv` の `code` 列（`name` 列が路線名、`extra` 列が独自追加路線か）
  - 例: `grep ',東海道新幹線,' src/line.csv` → `1002`
- 型定義・変換・検証の実装（正はこちら）
  - `src/ts/model/geo.ts`: `JSONPolylineSrc` / `jsonPolylineSrc`（独自形式）, `JSONPolylineGeo` / `jsonPolyline`（GeoJSON）, `convertToPolylineGeo`（変換）
  - `src/ts/validate/geo.ts`: `validatePolylineSrc`（check時）, `validateGeoPolyline`（ビルド後テスト）
- ポリラインが無い路線は `src/check/polyline_ignore.csv`（`name` 列に路線名）に登録が必要

## 独自形式（src）

```json
{
  "name": "JR石勝線",
  "origin": "rail-history.org",
  "point_list": [
    {"start": "新夕張", "end": "新得", "points": [{"lat":42.9399,"lng":142.03949}, ...]},
    {"start": "紅葉山", "end": "登川", "extra": true, "points": [...]},
    {"start": "夕張", "end": "新夕張", "closed": true, "points": [...]}
  ]
}
```

- `name`: `src/line.csv` の同じ code の `name` と完全一致（必須）
- `origin`: 任意の出典メモ。ルート直下の未知属性は許容され、ビルドで破棄される
- `point_list[]`: セグメント。1要素が GeoJSON の `Feature(LineString)` 1つになる
  - `start` / `end`: 端点のタグ。**同じタグの端点同士が接続する**。駅名が多いが分岐点・トンネル等の任意名でもよい（例 `旧線分岐`, `塩山１`）。`start === end` は環状
  - `points`: `start` → `end` の順の `{lng, lat}` 列。キー順・小数桁はファイルにより揃っていない
  - `extra: true`: 独自追加の廃止区間。**main ビルドで除外**、extra ビルドのみ出力
  - `closed: true`: 廃止区間の注記。ビルド結果には影響しない

スキーマで表現できない制約（`npm run check` で検査）:
1. 同じタグを持つ端点の座標が完全一致
2. 同一セグメント内で連続する座標の重複禁止
3. セグメント全体が連結グラフ（環状セグメントは連結判定から除外）
4. 環状セグメントは始点＝終点の座標、点数 3 以上

## 変換（src → GeoJSON）

`convertToPolylineGeo(src, dataset)`:
- `point_list[i]` → `features[i]`（`dataset === 'main'` なら `extra: true` を除外）
- `{lng, lat}` → `[lng, lat]`（**経度が先**）。小数点以下5桁に四捨五入（`Math.round(v * 1e5 + 2**-10) / 1e5`）
- `properties.start/end` はタグをそのまま、`properties.name` は路線名
- `properties.north/south/east/west` は出力される全座標の範囲
- extra 路線（`src/line.csv` の `extra=1`）は main に出力されない

ビルド後テストでは更に、路線の登録駅（`src/line/{code}.json`）の座標がポリライン範囲 ±0.15°（約20km）に収まることを検査する。

## 作業ルール（CLAUDE.md より）

- MUST: ポリラインを追加・編集する前に必ずユーザーの確認を取る（地図での目視確認が必要なため）
- MUST: `out/**` は直接編集しない。ローカルで `npm run build` しない（リモートでビルド）
- 実行してよい npm スクリプトは `npm run check` のみ
- `extra` 属性を持つ区間・独自追加路線の追加・修正は禁止
- 座標の作成・修正は原則 [Polyline Editor](https://seo-4d696b75.github.io/polyline-editor/) でユーザーが行う。エージェントは手で座標を創作しない
- 大きなファイルを丸ごと読まない（数千行ある）。下の補助スクリプトや `grep -n '"start"'` で構造を把握する
- 編集時は既存ファイルの書式（インデント・キー順・桁数）に合わせ、差分を最小にする

## 補助スクリプト（読み取り専用）

```bash
python3 -I .claude/skills/station-polyline/scripts/inspect_polyline.py <code|路線名>
```

セグメント一覧・タグ座標・連結性・端点一致・重複・登録駅のポリライン範囲判定を表示し、問題があれば `NG` と終了コード 1 を返す。

```bash
python3 -I .claude/skills/station-polyline/scripts/inspect_polyline.py <code> --geojson main|extra
```

ビルドと同一の GeoJSON を標準出力に出す（`out/` に書かずに変換結果を確認・地図表示する用）。結果は scratchpad など作業ディレクトリ外に保存する。

## よくある作業

- **欠損区間の追加**: ユーザーに確認 → Polyline Editor で作成された座標をセグメントとして追加。端点タグと座標を接続先セグメントの端点に一致させる → `inspect_polyline.py` → `npm run check`
- **「ポリライン範囲外」エラー**: どの駅が外れているか確認し、欠けている区間を特定してユーザーに報告（座標は創作しない）
- **「ポリラインが見つかりません」エラー**: ポリラインを用意するか、欠損を許すなら `src/check/polyline_ignore.csv` に追記（確認データなのでユーザー確認必須）
- **路線名変更**: `src/line.csv` と `src/polyline/{code}.json` の `name`、必要なら `polyline_ignore.csv` を揃える
