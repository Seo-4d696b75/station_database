# issue #214 末端区間のポリライン補完

https://github.com/Seo-4d696b75/station_database/issues/214 の「末端区間が法的な定義と異なる」路線について、欠けている末端区間のポリラインを、その区間が本来属する路線（移植元）から複製して追加する。

路線の定義の正は駅メモのゲームに準拠する（登録駅まで線を引く）。法的な区間の議論はしない。

1つの作業単位は1路線。1路線＝1ブランチ＝1コミット＝1PR とする。

## 対象路線

| code | 路線名 | 区間（issue の表記） | 移植元 | `--to` |
|:--|:--|:--|:--|:--|
| 11622 | JR舞鶴線 | 福知山〜綾部 | 11615 JR山陰本線(園部～豊岡) | 福知山 |
| 28010 | 東京メトロ副都心線 | 池袋〜和光市 | 28006 東京メトロ有楽町線 | 和光市 |
| 11631 | JR赤穂線 | 東岡山〜岡山 | 11609 JR山陽本線(姫路～岡山) | 岡山 |
| 11921 | JR唐津線 | 佐賀〜久保田 | 11905 JR長崎本線(鳥栖～長崎) | 佐賀 |
| 11341 | JR両毛線 | 新前橋〜高崎 | 11342 JR上越線 | 高崎 |
| 11716 | JR呉線 | 海田市〜広島, 糸崎〜三原 | 11611 JR山陽本線(三原～岩国), 11610 JR山陽本線(岡山～三原) | 広島（11611）, 糸崎（11610） |
| 11714 | JR芸備線 | 新見〜備中神代 | 11703 JR伯備線 | 新見 |
| 30008 | 名鉄常滑線 | 名鉄名古屋〜神宮前 | 30001 名鉄名古屋本線 | 名鉄名古屋 |
| 26002 | 東急目黒線 | 日吉〜田園調布 | 26001 東急東横線 | 日吉 |
| 11305 | JR武蔵野線 | 西船橋〜南船橋 | 11326 JR京葉線 | 南船橋 |
| 31025 | 近鉄京都線 | 大和西大寺〜近鉄奈良 | 31020 近鉄奈良線 | 近鉄奈良 |
| 11724 | JR岩徳線 | 徳山〜櫛ケ浜 | 11612 JR山陽本線(岩国～門司) | 徳山 |
| 11641 | JRおおさか東線 | 大阪〜新大阪 | 11602 JR東海道本線(京都線)(京都～大阪) | 大阪 |
| 11119 | JR江差線 | 函館〜五稜郭 | 11101 JR函館本線(函館～長万部) | 函館 |
| 30015 | 名鉄犬山線 | 名鉄名古屋〜枇杷島分岐点 | 30001 名鉄名古屋本線 | 名鉄名古屋 |
| 11704 | JR因美線 | 津山〜東津山 | 11634 JR姫新線(佐用～新見) | 津山 |
| 11421 | JR越美北線(九頭竜線) | 福井〜越前花堂 | 99455 ハピラインふくい線 | 福井 |
| 21008 | 東武宇都宮線 | 栃木〜新栃木 | 21003 東武日光線 | 栃木 |
| 33001 | 京阪本線 | 出町柳〜三条 | 33004 京阪鴨東線 | 出町柳 |
| 26004 | 東急大井町線 | 二子玉川〜溝の口 | 26003 東急田園都市線 | 溝の口 |
| 32005 | 南海加太線 | 加太〜和歌山市 | 32001 南海本線 | 和歌山市 |
| 11723 | JR小野田線 | 宇部新川〜居能 | 11721 JR宇部線 | 宇部新川 |
| 99634 | 神鉄公園都市線 | 三田〜横山 | 99633 神鉄三田線 | 三田 |
| 30006 | 名鉄豊田線 | 梅坪〜豊田市 | 30005 名鉄三河線 | 豊田市 |
| 99803 | 琴電長尾線 | 高松築港〜瓦町 | 99802 琴電琴平線 | 高松築港 |
| 23002 | 京成押上線 | 青砥〜京成高砂 | 23001 京成本線 | 京成高砂 |

- 呉線は区間が2つある。`copy_section.py` を2回実行し、1コミットにまとめる
- 路線名・コードは必ず `src/line.csv` で確認する

## この作業に限った例外と許可

- SKILL.md の「座標を創作しない／Polyline Editor でユーザーが作る」の例外として、対象路線の `src/polyline/{code}.json` に限り、移植元のポリラインから `copy_section.py` で座標を複製して追加してよい
  - 座標を手で書かない。移植元のファイルや他のファイルは編集しない
- 人間による確認は、PR でのレビューとマージで行う。CLAUDE.md の「ポリラインの編集前にユーザーの確認を取る」は、この PR レビューで満たすものとする
- 次の操作は事前に許可されている。作業中にユーザーへの確認は不要
  - 作業ブランチ `feature/issue-214/{code}` の作成、コミット、push
  - `develop/issue-214` を base とした PR の作成と、その PR へのコメント投稿
  - レビュー後の修正での `git commit --amend` と、自分の作業ブランチへの `git push --force-with-lease`
- 次の操作はしない
  - `develop/issue-214` や `main` への push、PR のマージ、他の作業ブランチの操作
  - uv でのパッケージのインストール。`render_polyline.py` は `uv run --offline` で実行し、キャッシュにない場合はインストールせずに画像生成を省いて、その旨を報告する

## 手順

### 1. 作業環境の準備

並行して作業するため、必ず専用の git worktree で作業する。

```bash
git fetch origin
# 既に隔離された worktree の中にいる場合
git switch -c feature/issue-214/{code} origin/develop/issue-214
# そうでない場合（リポジトリのルートから）
git worktree add ../station_database-214-{code} -b feature/issue-214/{code} origin/develop/issue-214
cd ../station_database-214-{code}
```

worktree には git 管理外の `node_modules` と `src/.env.local`（`npm run check` が使う API キー）がない。どちらも、メインの作業ツリーにあるものへのシンボリックリンクを張る（`npm ci` はしない）。どちらのリンクも `.gitignore` の対象なのでコミットされない。

```bash
MAIN="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
ln -s "$MAIN/node_modules" node_modules
ln -s "$MAIN/src/.env.local" src/.env.local
```

- MUST: `src/.env.local` の中身は読まない（CLAUDE.md）。リンクを張るだけにする
- 以降のコマンドは、すべて worktree のルートで実行する。worktree がメインのリポジトリの外にあると、Bash ツールの作業ディレクトリはコマンドごとに元に戻る。そのため、毎回 `cd <worktree の絶対パス> && ...` の形で実行する

### 2. 区間の切り出し

まずドライランで結果を確認する。

```bash
python3 -I .claude/skills/station-polyline/scripts/copy_section.py {code} --source {移植元code} --to {--to の駅} --dry-run
```

- `--join` は省略する。終点に最も近い末端タグが自動で選ばれる。選ばれたタグが区間の表記と矛盾しないか確認する
- `WARN`（端点の置き換え距離が約100mを超える）が出た場合は、そのまま進めてよい。ただし PR 本文に明記して、レビューでの確認を依頼する
- エラーになる場合や、区間付近の駅に登録駅が出てこない場合は、作業を止めて報告する

問題がなければ `--dry-run` を外して実行する。ファイルは規定の書式で書き込まれる。

### 3. 検証

```bash
python3 -I .claude/skills/station-polyline/scripts/inspect_polyline.py {code}        # OK になること（範囲外の駅がないこと）
python3 -I .claude/skills/station-polyline/scripts/format_polyline.py {code} --check
npm run check
git diff --stat   # src/polyline/{code}.json だけが変更されていること
```

### 4. 可視化と自己確認

```bash
uv run --offline --script .claude/skills/station-polyline/scripts/render_polyline.py {code} \
    --base origin/develop/issue-214 --out {出力先}
```

- 出力先は依頼時に指定されたディレクトリを使う。指定がなければ自分の scratchpad を使う。リポジトリの中には出力しない
- 生成した `region_NN.png` を Read で見る。追加区間が赤線だけで描かれ、移植元の線路に沿って登録駅まで届いていることを確認する
- 線が駅の手前で途切れて見える場合は、`git checkout -- src/polyline/{code}.json` で戻し、`--extend 2` を付けて切り出し直してもよい

### 5. コミット

1路線＝1コミット。メッセージは次の形式にする。

```
fix: {路線名}({code}) {区間（issue の表記）}のポリラインを追加

ref: #214
本来の{移植元の路線名}から移植

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

- `{路線名}` と `{移植元の路線名}` は `src/line.csv` の `name`。区間は上の表の「区間（issue の表記）」をそのまま使う
- 移植元が複数ある場合（呉線）は「本来のJR山陽本線(三原～岩国)、JR山陽本線(岡山～三原)から移植」のように「、」で並べる
- 例

```
fix: JR江差線(11119) 函館〜五稜郭のポリラインを追加

ref: #214
本来のJR函館本線(函館～長万部)から移植
```

### 6. PR の作成とコメント

```bash
git push -u origin feature/issue-214/{code}
gh pr create --base develop/issue-214 --head feature/issue-214/{code} --title "{コミットの1行目}" --body-file {本文ファイル}
python3 -I .claude/skills/station-polyline/scripts/pr_comment_polyline.py {code} --base origin/develop/issue-214 --out {出力先}/pr
gh pr comment {PR番号} --body-file {出力先}/pr/comment_01.md   # comment_NN.md ごとに投稿
```

PR 本文には次を書く。末尾に `🤖 Generated with [Claude Code](https://claude.com/claude-code)` を付ける。

- 追加した区間（新しいセグメントのタグと点の数）と移植元
- `copy_section.py` の出力（選ばれた `--join`、置き換え距離、区間付近の駅）。`WARN` があれば目立つように書く
- 検証の結果（`inspect_polyline.py` / `format_polyline.py --check` / `npm run check`）
- `ref: #214`

### 7. レビュー後の修正

人間から修正を求められたら、1路線＝1コミットを保つ。

```bash
# 修正後
git add src/polyline/{code}.json
git commit --amend --no-edit
git push --force-with-lease
```

修正後は手順 3〜4 の検証をやり直し、`pr_comment_polyline.py` で geojson コメントを新しく投稿する。

### 8. 報告

作業を依頼したエージェント（またはユーザー）には、次を返す。

- PR の URL
- 生成した PNG の絶対パス
- `WARN` や判断に迷った点
