#!/usr/bin/env python3
"""src/polyline/{code}.json の概要表示・検証（読み取り専用）

usage:
  python3 -I .claude/skills/station-polyline/scripts/inspect_polyline.py <code|路線名> [--geojson main|extra]

リポジトリのルートで実行すること。ファイルは一切書き換えない。
--geojson を指定すると build 相当の GeoJSON を標準出力へ出す（地図での目視確認用）。
"""
import csv
import json
import math
import sys
from collections import deque

# src/ts/validate/geo.ts POLYLINE_STATION_MARGIN
MARGIN = 0.15


def load_lines():
    with open("src/line.csv", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def find_line(lines, key):
    for line in lines:
        if key in (line["code"], line["name"]):
            return line
    cands = [l for l in lines if key in l["name"]]
    if len(cands) == 1:
        return cands[0]
    if cands:
        sys.exit("候補が複数あります: " + ", ".join(f'{l["code"]}:{l["name"]}' for l in cands))
    sys.exit(f"路線が見つかりません: {key}")


def round5(v):
    # convertToPolylineGeo と同じ丸め
    return math.floor(v * 1e5 + 2 ** -10 + 0.5) / 1e5


def to_geojson(src, dataset):
    features = []
    for seg in src["point_list"]:
        if dataset == "main" and seg.get("extra"):
            continue
        coords = [[round5(p["lng"]), round5(p["lat"])] for p in seg["points"]]
        features.append({
            "type": "Feature",
            "geometry": {"type": "LineString", "coordinates": coords},
            "properties": {"start": seg["start"], "end": seg["end"]},
        })
    all_pts = [c for f in features for c in f["geometry"]["coordinates"]]
    return {
        "type": "FeatureCollection",
        "features": features,
        "properties": {
            "name": src["name"],
            "north": max(c[1] for c in all_pts),
            "south": min(c[1] for c in all_pts),
            "east": max(c[0] for c in all_pts),
            "west": min(c[0] for c in all_pts),
        },
    }


def is_connected(segments):
    edges = [s for s in segments if s["start"] != s["end"]]
    if not edges:
        return True
    adj = {}
    for e in edges:
        adj.setdefault(e["start"], set()).add(e["end"])
        adj.setdefault(e["end"], set()).add(e["start"])
    seen = {edges[0]["start"]}
    queue = deque(seen)
    while queue:
        for n in adj[queue.popleft()]:
            if n not in seen:
                seen.add(n)
                queue.append(n)
    return seen == set(adj)


def line_stations(code):
    try:
        with open(f"src/line/{code}.json", encoding="utf-8") as f:
            detail = json.load(f)
    except FileNotFoundError:
        return []
    with open("src/station.csv", encoding="utf-8") as f:
        stations = {r["code"]: r for r in csv.DictReader(f)}
    result = []
    for s in detail["station_list"]:
        st = stations.get(str(s["code"]))
        if st:
            # 駅自体の extra に加えて路線登録単位の extra も考慮する
            result.append({**st, "extra": "1" if s.get("extra") else st["extra"]})
    return result


def main():
    args = sys.argv[1:]
    dataset = None
    if "--geojson" in args:
        i = args.index("--geojson")
        dataset = args[i + 1]
        del args[i:i + 2]
    if len(args) != 1:
        sys.exit(__doc__)

    line = find_line(load_lines(), args[0])
    path = f"src/polyline/{line['code']}.json"
    try:
        with open(path, encoding="utf-8") as f:
            src = json.load(f)
    except FileNotFoundError:
        sys.exit(f"{path} がありません（src/check/polyline_ignore.csv への登録有無を確認）")

    if dataset:
        print(json.dumps(to_geojson(src, dataset), ensure_ascii=False))
        return

    errors = []
    print(f"{path}  {line['name']}  closed={line['closed']} extra={line['extra']}")
    if src["name"] != line["name"]:
        errors.append(f"name 不一致: {src['name']} != {line['name']}")

    tags = {}
    print(f"\nsegments ({len(src['point_list'])}):")
    for i, seg in enumerate(src["point_list"]):
        pts = seg["points"]
        flags = " ".join(k for k in ("extra", "closed") if seg.get(k))
        print(f"  [{i}] {seg['start']} -> {seg['end']}  points={len(pts)} {flags}")
        if len(pts) < 2:
            errors.append(f"[{i}] 座標点が2未満")
            continue
        for tag, p in ((seg["start"], pts[0]), (seg["end"], pts[-1])):
            pos = (p["lng"], p["lat"])
            if tag in tags and tags[tag] != pos:
                errors.append(f"[{i}] タグ '{tag}' の座標が不一致 {tags[tag]} != {pos}")
            tags.setdefault(tag, pos)
        for j in range(1, len(pts)):
            if (pts[j]["lng"], pts[j]["lat"]) == (pts[j - 1]["lng"], pts[j - 1]["lat"]):
                errors.append(f"[{i}] points[{j}] が直前の座標と重複")
        if seg["start"] == seg["end"] and (pts[0] != pts[-1] or len(pts) < 3):
            errors.append(f"[{i}] 環状セグメントの始点・終点が不一致または点数不足")

    if not is_connected(src["point_list"]):
        errors.append("セグメントが連結グラフではない")

    stations = line_stations(line["code"])
    station_names = {s["name"] for s in stations} | {s["original_name"] for s in stations}
    print("\ntags (*: 登録駅名と一致しない任意地点):")
    for tag, (lng, lat) in tags.items():
        mark = " " if tag in station_names else "*"
        print(f"  {mark} {tag}: lng={lng} lat={lat}")

    for ds in ("main", "extra"):
        if ds == "main" and line["extra"] == "1":
            continue
        try:
            geo = to_geojson(src, ds)
        except ValueError:
            errors.append(f"{ds}: 出力されるセグメントがない")
            continue
        b = geo["properties"]
        print(f"\nbounds({ds}): N={b['north']} S={b['south']} E={b['east']} W={b['west']}")
        for s in stations:
            if ds == "main" and s["extra"] == "1":
                continue
            lat, lng = float(s["lat"]), float(s["lng"])
            if not (b["south"] - MARGIN <= lat <= b["north"] + MARGIN
                    and b["west"] - MARGIN <= lng <= b["east"] + MARGIN):
                errors.append(f"{ds}: 駅 {s['name']} がポリライン範囲外 lat={lat} lng={lng}")

    print()
    if errors:
        print("NG:")
        for e in errors:
            print("  - " + e)
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
