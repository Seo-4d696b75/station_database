---
name: station-polyline
description: 路線ポリラインデータ（src/polyline/{code}.json と out/*/polyline/{code}.json）の確認・編集・検証の手引き。路線の線形・座標・セグメント・ポリライン欠損・ポリライン範囲外エラー・Polyline Editor・ポリラインの地図画像での確認・ポリライン編集を含む PR の作成に関する作業や質問のときに使う。
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
  - `points`: `start` → `end` の順に並んだ `{lng, lat}` の列。既存ファイルではキーの順序や小数の桁数が揃っていない（エージェントが書くときは「ファイルの書式」に従う）
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
- エージェントが編集・追加したファイルは、下の「ファイルの書式」に従って整形する

## ファイルの書式

エージェントが編集・追加する `src/polyline/{code}.json` は次の書式にする。

- インデントは 2 スペースの、一般的な pretty format にする（`"key": value`、要素ごとに改行）
- 座標点だけは 1 行にまとめ、空白を入れず、`lat`, `lng` の順に書く
- 座標の値は小数点以下 5 桁までを推奨する。6 桁目以降は四捨五入する。ビルドでも 5 桁に丸められるので、それより細かい値は成果物に残らない

```json
{
  "name": "JR石勝線",
  "point_list": [
    {
      "start": "紅葉山",
      "end": "登川",
      "extra": true,
      "points": [
        {"lat":42.93544,"lng":142.03598},
        {"lat":42.93817,"lng":142.03905}
      ]
    }
  ]
}
```

整形は手作業ではなく、スクリプトで行う。

```bash
python3 -I .claude/skills/station-polyline/scripts/format_polyline.py <code|路線名|path> [...]          # 整形して上書き
python3 -I .claude/skills/station-polyline/scripts/format_polyline.py <code|路線名|path> [...] --check  # 確認のみ
```

- 数値の表記（末尾の 0 など）は元のまま残す。小数点以下の桁数の丸めは行わないので、5 桁に丸めるのは座標を書くときに行う。座標点以外のキーの順序もそのまま残す。整形の前後で内容が変わらないことはスクリプトが検査する
- 現時点では、この書式に従っていない既存ファイルがほとんどである。整形するのは、エージェントが編集・追加したファイルだけにする。編集していないファイルを一括で整形しない（差分が膨れてレビューできなくなるため）
- 書式に従っていない既存ファイルを編集した場合は、整形による差分もそのファイル全体に出る。この点をユーザーに伝える

## 補助スクリプト（読み取り専用）

`scripts/` 配下のスクリプトは、`format_polyline.py`（指定したファイルを整形して上書きする）と `copy_section.py`（対象路線のファイルに区間を追加する）を除いて、どれも `src/` を読むだけで書き換えない。共通処理は `scripts/polyline_lib.py` にある。

```bash
python3 -I .claude/skills/station-polyline/scripts/inspect_polyline.py <code|路線名>
```

セグメント一覧・タグ座標・連結性・端点一致・重複・登録駅のポリライン範囲判定を表示し、問題があれば `NG` と終了コード 1 を返す。

```bash
python3 -I .claude/skills/station-polyline/scripts/inspect_polyline.py <code> --geojson main|extra
```

ビルドと同一の GeoJSON を標準出力に出す（`out/` に書かずに変換結果を確認・地図表示する用）。結果は scratchpad など作業ディレクトリ外に保存する。

## 地図画像での確認（人間のレビュー用）

ポリラインを編集したら、地図に描画した PNG を作ってユーザーに確認してもらう。ユーザーに見せる前に、エージェント自身も Read で画像を見て、明らかな破綻（飛び点、逆走、接続切れ、線路からの大きなずれ）がないか確かめる。

```bash
uv run --script .claude/skills/station-polyline/scripts/render_polyline.py <code|路線名> --out <DIR> [--base REV] [--dataset main|extra]
```

- 出力
  - `overview.png`: 路線全体
  - `region_NN.png`: 変更箇所ごとの拡大図（`--base` との差分から自動で切り出す）
- 凡例
  - 灰の太線: 変更前（`--base`、既定 `HEAD`）
  - 赤の細線: 変更後（作業ツリー）
  - 青の点: 登録駅
  - 見え方: 変更のない区間は灰の縁取りの付いた赤線、削除された区間は灰だけ、追加された区間は赤だけになる
- 背景は地理院タイル（淡色地図）。画像を共有するときは「出典：国土地理院」を併記する
- `--out` は scratchpad などリポジトリ外にする。画像はコミットしない
- コミット済みの変更を確認するときは `--base` に変更前のリビジョンを指定する（例 `--base main`）

### 依存パッケージ（uv）

- 依存（`staticmap`、Pillow、requests）はスクリプト先頭の PEP 723 メタデータで宣言している。`uv run --script` を実行すると uv のキャッシュにある一時環境へインストールされる。リポジトリには何も追加されない
- MUST: このスクリプトを初めて `uv run` する前（パッケージのインストールが発生するとき）は、必ず人間の許可を求める。許可を得るまで実行しない
- `pip install` や、プロジェクトへの `pyproject.toml` / `requirements.txt` の追加はしない
- uv が無い環境では、画像の生成をやめてユーザーに相談する

## ポリライン編集を含む PR の作成

路線ポリラインの編集を含む PR を作るよう頼まれたときは、PR を作成した後、変更箇所を GitHub の ```` ```geojson ```` コードブロック（地図として描画される）で PR にコメントする。

```bash
python3 -I .claude/skills/station-polyline/scripts/pr_comment_polyline.py <code> [<code> ...] \
    --base "$(git merge-base origin/main HEAD)" --out <DIR>
gh pr comment <PR番号> --body-file <DIR>/comment_01.md   # comment_NN.md ごとに投稿
```

- 変更した路線は `git diff --name-only "$(git merge-base origin/main HEAD)" -- src/polyline/` で洗い出す
- コメントには、路線ごとに「変更後の路線全体」の地図と、変更箇所ごとに「変更後」「変更前」の地図を別々に載せる（GitHub の geojson 表示は線の色指定を反映しないため）
- 変更箇所の地図には、変更箇所の前後だけを切り出して載せる。GitHub のコメント上限（65,536文字）に収まるよう、コメントを分割したり座標を間引いたりする
- 投稿前に生成したコメント本文をユーザーに見せて、投稿してよいか確認する（外部への書き込みのため）

## 他路線からの区間の複製

```bash
python3 -I .claude/skills/station-polyline/scripts/copy_section.py <対象code> --source <移植元code> --to <駅名|タグ> [--join <既存タグ>] [--extend N] [--dry-run]
```

移植元のポリラインから、`--join`（対象路線の既存タグ。省略時は終点に最も近い末端タグ）から `--to` までの経路の座標をそのまま複製する。複製した区間は、対象路線に新しいセグメントとして追加される。始点は既存タグの座標に合わせて接続する。対象ファイルを書き換えるスクリプトなので、使ってよいのは座標の複製が許可された作業に限る。

## issue #214 末端区間の補完

issue #214 の「末端区間のポリラインが欠けている路線」の作業を頼まれたときは、[references/issue-214-terminal-section.md](references/issue-214-terminal-section.md) の手順に従う。対象路線、例外の範囲、ブランチ、コミットメッセージ、PR の作り方はそこに書いてある。

## よくある作業

- **欠損区間の追加**: ユーザーに確認 → Polyline Editor で作成された座標をセグメントとして追加。端点タグと座標を接続先セグメントの端点に一致させる → `inspect_polyline.py` → `npm run check` → `render_polyline.py` の画像でユーザーに確認してもらう
- **「ポリライン範囲外」エラー**: どの駅が外れているか確認し、欠けている区間を特定してユーザーに報告（座標は創作しない）
- **「ポリラインが見つかりません」エラー**: ポリラインを用意するか、欠損を許すなら `src/check/polyline_ignore.csv` に追記（確認データなのでユーザー確認必須）
- **路線名変更**: `src/line.csv` と `src/polyline/{code}.json` の `name`、必要なら `polyline_ignore.csv` を揃える
