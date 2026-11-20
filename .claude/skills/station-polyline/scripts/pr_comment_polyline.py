#!/usr/bin/env python3
"""ポリライン変更箇所を GitHub の geojson コードブロックで表した PR コメント本文を生成する（読み取り専用）

usage:
  python3 -I .claude/skills/station-polyline/scripts/pr_comment_polyline.py \\
      <code|路線名> [<code|路線名> ...] --base REV --out <DIR>

  --base  変更前として比較する git リビジョン（PR なら `git merge-base origin/main HEAD`）
  --out   コメント本文 comment_NN.md の出力先ディレクトリ（リポジトリ外を推奨）

GitHub のコメント上限（65,536文字）を超えないようコメントを分割し、
1ブロックが大きすぎる場合は座標を間引く。投稿は `gh pr comment <PR> --body-file <file>` で行う。
"""
import json
import os
import sys

sys.dont_write_bytecode = True  # skills 配下に __pycache__ を作らない
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from polyline_lib import (  # noqa: E402
    changed_regions, coords, find_line, in_bbox, line_stations, load_lines, load_src, round5, segments,
)

COMMENT_LIMIT = 60000  # GitHub 上限 65,536 文字に余裕をもたせる
BLOCK_LIMIT = 50000
CONTEXT_POINTS = 10  # 変更範囲の前後に含める座標数
STATUS_LABEL = {"added": "追加", "removed": "削除", "modified": "変更"}


def thin(pts, limit):
    if len(pts) <= limit:
        return pts
    step = (len(pts) - 1) / (limit - 1)
    return [pts[round(i * step)] for i in range(limit)]


def part(pts, rng):
    if not pts:
        return []
    if rng is None:
        return pts
    return pts[max(0, rng[0] - CONTEXT_POINTS):rng[1] + CONTEXT_POINTS + 1]


def block(pts, region, stations):
    """変更前・変更後のどちらか一方の線と、範囲内の登録駅を1つの地図にする

    GitHub の geojson 表示は線の色指定（stroke）を反映しないため、変更前と変更後は別々の地図に分ける
    """
    limit = len(pts)
    while True:
        line = thin(pts, limit)
        features = [{
            "type": "Feature",
            "geometry": {"type": "LineString", "coordinates": [[round5(lng), round5(lat)] for lng, lat in line]},
            "properties": {},
        }]
        for st in stations:
            p = (float(st["lng"]), float(st["lat"]))
            if in_bbox(p, region["bbox"]):
                features.append({
                    "type": "Feature",
                    "geometry": {"type": "Point", "coordinates": [round5(p[0]), round5(p[1])]},
                    "properties": {"name": st["name"]},
                })
        text = json.dumps({"type": "FeatureCollection", "features": features},
                          ensure_ascii=False, separators=(",", ":"))
        if len(text) <= BLOCK_LIMIT:
            note = "（座標を間引いて表示）" if limit < len(pts) else ""
            return f"```geojson\n{text}\n```\n", note
        limit = int(limit * BLOCK_LIMIT / len(text) * 0.9)


def overview_block(src, stations):
    """変更後の路線全体（全セグメント）と全登録駅を1つの地図にする"""
    seg_pts = [coords(seg) for seg in segments(src)]
    ratio = 1.0
    while True:
        features = [{
            "type": "Feature",
            "geometry": {
                "type": "LineString",
                "coordinates": [[round5(lng), round5(lat)] for lng, lat in thin(pts, max(2, int(len(pts) * ratio)))],
            },
            "properties": {},
        } for pts in seg_pts]
        features += [{
            "type": "Feature",
            "geometry": {"type": "Point", "coordinates": [round5(float(st["lng"])), round5(float(st["lat"]))]},
            "properties": {"name": st["name"]},
        } for st in stations]
        text = json.dumps({"type": "FeatureCollection", "features": features},
                          ensure_ascii=False, separators=(",", ":"))
        if len(text) <= BLOCK_LIMIT:
            note = "（座標を間引いて表示）" if ratio < 1.0 else ""
            return f"```geojson\n{text}\n```\n", note
        ratio *= BLOCK_LIMIT / len(text) * 0.9


def main():
    args = sys.argv[1:]
    opts = {"--base": None, "--out": None}
    for key in opts:
        if key in args:
            i = args.index(key)
            opts[key] = args[i + 1]
            del args[i:i + 2]
    if not args or not opts["--base"] or not opts["--out"]:
        sys.exit(__doc__)

    lines = load_lines()
    sections = []
    for key in args:
        line = find_line(lines, key)
        old_src = load_src(line["code"], opts["--base"])
        new_src = load_src(line["code"])
        stations = line_stations(line["code"])
        regions = changed_regions(old_src, new_src)
        if regions and new_src is not None:
            code_block, note = overview_block(new_src, stations)
            sections.append(f"#### {line['name']} ({line['code']}) 路線全体（変更後）{note}\n\n{code_block}\n")
        for r in regions:
            sec = f"#### {line['name']} ({line['code']}) {r['label']} [{STATUS_LABEL[r['status']]}]\n\n"
            for title, pts, rng in (("変更後", r["new"], r["new_range"]), ("変更前", r["old"], r["old_range"])):
                pts = part(pts, rng)
                if len(pts) >= 2:
                    code_block, note = block(pts, r, stations)
                    sec += f"**{title}**{note}\n\n{code_block}\n"
            sections.append(sec)

    if not sections:
        sys.exit("変更箇所がありません")

    header = (f"### 路線ポリラインの変更箇所\n\n"
              f"路線ごとに、変更後の路線全体の地図と、変更箇所ごとの変更後・変更前（`{opts['--base']}`）の地図を示します。"
              f"点は範囲内の登録駅です（クリックで駅名を表示）。\n\n")
    comments = []
    body = header
    for sec in sections:
        if len(body) + len(sec) > COMMENT_LIMIT and body != header:
            comments.append(body)
            body = header
        body += sec + "\n"
    comments.append(body)

    os.makedirs(opts["--out"], exist_ok=True)
    for n, body in enumerate(comments, 1):
        path = os.path.join(opts["--out"], f"comment_{n:02d}.md")
        with open(path, "w", encoding="utf-8") as f:
            f.write(body)
        print(f"{path}  {len(body)} chars")


if __name__ == "__main__":
    main()
