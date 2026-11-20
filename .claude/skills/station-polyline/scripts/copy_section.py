#!/usr/bin/env python3
"""他路線のポリラインから区間を切り出して、対象路線にセグメントとして追加する

usage:
  python3 -I .claude/skills/station-polyline/scripts/copy_section.py <対象 code|路線名> \\
      --source <移植元 code|路線名> --to <駅名|タグ> [--join <対象路線の既存タグ>] [--to-tag NAME] [--extend N] [--dry-run]

  --source   座標を複製する移植元の路線
  --join     新しいセグメントの始点。対象路線の既存のタグ（末端の駅など）。座標はそのタグに一致させる
             省略時は、対象路線の末端タグのうち終点に最も近いものを選ぶ
  --to       新しいセグメントの終点。対象路線の登録駅名（name / original_name）、移植元のタグ、
             または対象路線の既存タグ（その場合は座標を一致させて区間の欠損を埋める）
  --to-tag   終点のタグ名（既定: 駅なら original_name、タグならそのまま）
  --extend   終点を移植元の線に沿って N 点先まで延ばす（既定: 0 = 駅に最も近い点で止める）
             駅を少し越えるところまで線を描きたい場合に使う。既存タグへの接続時は使えない
  --dry-run  ファイルを書き換えずに結果だけ表示する

移植元のポリラインを、座標が一致する点で繋がったグラフとみなし、
--join に最も近い点から --to に最も近い点までの最短経路の座標をそのまま複製する。
端点が対象路線の既存タグの場合は、その座標で置き換えて接続させる。
書き込み時は format_polyline.py と同じ書式で整形する。
"""
import heapq
import json
import math
import os
import sys
from decimal import Decimal

sys.dont_write_bytecode = True  # skills 配下に __pycache__ を作らない
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from format_polyline import dump  # noqa: E402
from polyline_lib import find_line, line_stations, load_lines  # noqa: E402

# 端点の置き換え距離（度）がこれを超えたら警告する。約100m
SNAP_WARN = 0.001


def dist(a, b):
    return math.hypot(float(a[0]) - float(b[0]), float(a[1]) - float(b[1]))


def tag_coords(src):
    tags = {}
    for seg in src["point_list"]:
        for tag, p in ((seg["start"], seg["points"][0]), (seg["end"], seg["points"][-1])):
            tags.setdefault(tag, (p["lng"], p["lat"]))
    return tags


def terminal_tags(src):
    """ちょうど1つのセグメントの端点になっているタグ（環状セグメントは除く）"""
    degree = {}
    for seg in src["point_list"]:
        if seg["start"] == seg["end"]:
            continue
        for tag in (seg["start"], seg["end"]):
            degree[tag] = degree.get(tag, 0) + 1
    return [t for t, n in degree.items() if n == 1]


def graph(src):
    """座標をノード、セグメント内で隣り合う点を辺とするグラフ"""
    adj = {}
    for seg in src["point_list"]:
        pts = [(p["lng"], p["lat"]) for p in seg["points"]]
        for a, b in zip(pts, pts[1:]):
            d = dist(a, b)
            adj.setdefault(a, []).append((b, d))
            adj.setdefault(b, []).append((a, d))
    return adj


def extend(adj, path, n):
    """経路の終点から、まだ通っていない隣接点を辿って n 点延ばす。分岐では始点から遠い方へ進む"""
    visited = set(path)
    for _ in range(n):
        cands = [p for p, _ in adj.get(path[-1], []) if p not in visited]
        if not cands:
            break
        nxt = max(cands, key=lambda p: dist(p, path[0]))
        path.append(nxt)
        visited.add(nxt)
    return path


def shortest_path(adj, start, goal):
    prev = {start: None}
    cost = {start: 0.0}
    queue = [(0.0, 0, start)]
    n = 0
    while queue:
        c, _, node = heapq.heappop(queue)
        if node == goal:
            break
        if c > cost[node]:
            continue
        for nxt, d in adj.get(node, []):
            if c + d < cost.get(nxt, math.inf):
                cost[nxt] = c + d
                prev[nxt] = node
                n += 1
                heapq.heappush(queue, (c + d, n, nxt))
    if goal not in prev:
        sys.exit("移植元のポリライン上で経路が見つかりません")
    path = []
    node = goal
    while node is not None:
        path.append(node)
        node = prev[node]
    return list(reversed(path))


def nearest(src, pos):
    return min(((p["lng"], p["lat"]) for seg in src["point_list"] for p in seg["points"]),
               key=lambda p: dist(p, pos))


def load(code):
    with open(f"src/polyline/{code}.json", encoding="utf-8") as f:
        return json.load(f, parse_float=Decimal)


def main():
    args = sys.argv[1:]
    dry = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]
    opts = {"--source": None, "--join": None, "--to": None, "--to-tag": None, "--extend": "0"}
    for key in opts:
        if key in args:
            i = args.index(key)
            opts[key] = args[i + 1]
            del args[i:i + 2]
    if len(args) != 1 or not all(opts[k] for k in ("--source", "--to")):
        sys.exit(__doc__)

    lines = load_lines()
    target_line = find_line(lines, args[0])
    source_line = find_line(lines, opts["--source"])
    target = load(target_line["code"])
    source = load(source_line["code"])
    target_tags = tag_coords(target)
    source_tags = tag_coords(source)

    to = opts["--to"]
    stations = line_stations(target_line["code"])
    station = next((s for s in stations if to in (s["name"], s["original_name"])), None)
    if to in target_tags:
        to_pos, to_tag, to_snap = target_tags[to], to, True
    elif station:
        to_pos = (Decimal(station["lng"]), Decimal(station["lat"]))
        to_tag, to_snap = station["original_name"], False
    elif to in source_tags:
        to_pos, to_tag, to_snap = source_tags[to], to, False
    else:
        sys.exit(f"--to '{to}' が対象路線の登録駅・タグ、移植元のタグのいずれにもありません")
    to_tag = opts["--to-tag"] or to_tag
    if not to_snap and to_tag in target_tags:
        sys.exit(f"終点タグ '{to_tag}' は対象路線に既にあります。--to-tag で別名を指定してください")
    n_extend = int(opts["--extend"])
    if to_snap and n_extend:
        sys.exit("既存タグへ接続する場合は --extend を使えません")

    join = opts["--join"]
    if join is None:
        ends = [t for t in terminal_tags(target) if t != to_tag]
        if not ends:
            sys.exit("対象路線に末端のタグがありません。--join を指定してください")
        join = min(ends, key=lambda t: dist(target_tags[t], to_pos))
        print(f"--join 省略: 終点に最も近い末端タグ '{join}' を選択（候補: {', '.join(ends)}）")
    if join not in target_tags:
        sys.exit(f"--join '{join}' は対象路線のタグにありません: {', '.join(target_tags)}")
    join_pos = target_tags[join]

    start = nearest(source, join_pos)
    goal = nearest(source, to_pos)
    adj = graph(source)
    path = extend(adj, shortest_path(adj, start, goal), n_extend)
    warnings = []
    join_gap = dist(start, join_pos)
    if path[0] != join_pos:
        path[0] = join_pos
    if join_gap > SNAP_WARN:
        warnings.append(f"始点 '{join}' と移植元の最寄り点が {join_gap:.5f}° 離れています")
    end_gap = dist(goal, to_pos)
    if to_snap:
        path[-1] = to_pos
        if end_gap > SNAP_WARN:
            warnings.append(f"終点 '{to_tag}' と移植元の最寄り点が {end_gap:.5f}° 離れています")
    # 置き換えで生じた連続重複を除く
    path = [p for i, p in enumerate(path) if i == 0 or p != path[i - 1]]
    if len(path) < 2:
        sys.exit("切り出した区間の座標点が2未満です")

    print(f"対象: {target_line['code']} {target_line['name']}")
    print(f"移植元: {source_line['code']} {source_line['name']}")
    print(f"新しいセグメント: {join} -> {to_tag}  points={len(path)}")
    print(f"  始点の置き換え距離: {join_gap:.5f}°")
    print(f"  終点{'の置き換え' if to_snap else 'と駅・タグ'}の距離: {end_gap:.5f}°")
    for s in stations:
        pos = (Decimal(s["lng"]), Decimal(s["lat"]))
        d = min(dist(p, pos) for p in path)
        if d < 0.01:
            print(f"  区間付近の駅: {s['name']} ({d:.5f}°)")
    for w in warnings:
        print(f"WARN: {w}")

    if dry:
        return
    target["point_list"].append({
        "start": join,
        "end": to_tag,
        "points": [{"lat": lat, "lng": lng} for lng, lat in path],
    })
    path_out = f"src/polyline/{target_line['code']}.json"
    with open(path_out, "w", encoding="utf-8") as f:
        f.write(dump(target) + "\n")
    print(f"written: {path_out}")


if __name__ == "__main__":
    main()
