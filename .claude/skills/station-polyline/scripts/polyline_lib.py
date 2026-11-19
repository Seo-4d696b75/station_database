"""路線ポリライン補助スクリプトの共通処理（標準ライブラリのみ）

リポジトリのルートをカレントディレクトリとして使うこと。
"""
import csv
import json
import math
import subprocess
import sys


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


def load_src(code, rev=None):
    """src/polyline/{code}.json を読む。rev 指定時は git のそのリビジョンから。存在しなければ None"""
    path = f"src/polyline/{code}.json"
    if rev is None:
        try:
            with open(path, encoding="utf-8") as f:
                return json.load(f)
        except FileNotFoundError:
            return None
    proc = subprocess.run(["git", "show", f"{rev}:{path}"], capture_output=True, text=True)
    if proc.returncode != 0:
        return None
    return json.loads(proc.stdout)


def round5(v):
    # convertToPolylineGeo と同じ丸め
    return math.floor(v * 1e5 + 2 ** -10 + 0.5) / 1e5


def segments(src, dataset=None):
    """dataset == 'main' なら build と同様に extra セグメントを除外する"""
    if src is None:
        return []
    return [s for s in src["point_list"] if not (dataset == "main" and s.get("extra"))]


def coords(seg):
    return [(p["lng"], p["lat"]) for p in seg["points"]]


def to_geojson(src, dataset):
    features = []
    for seg in segments(src, dataset):
        features.append({
            "type": "Feature",
            "geometry": {
                "type": "LineString",
                "coordinates": [[round5(lng), round5(lat)] for lng, lat in coords(seg)],
            },
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


def line_stations(code):
    """路線の登録駅。路線登録単位の extra も駅の extra として反映する"""
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
            result.append({**st, "extra": "1" if s.get("extra") else st["extra"]})
    return result


def bbox(points):
    lngs = [p[0] for p in points]
    lats = [p[1] for p in points]
    return min(lngs), min(lats), max(lngs), max(lats)


def pad_bbox(b, ratio=0.2, minimum=0.005):
    w, s, e, n = b
    dx = max((e - w) * ratio, minimum)
    dy = max((n - s) * ratio, minimum)
    return w - dx, s - dy, e + dx, n + dy


def in_bbox(p, b):
    return b[0] <= p[0] <= b[2] and b[1] <= p[1] <= b[3]


# 差分点をまとめるときの距離（度）。これより離れた変更箇所は別の領域にする
CLUSTER_DISTANCE = 0.03


def _cluster(points):
    clusters = []  # [bbox, points]
    for p in points:
        for c in clusters:
            w, s, e, n = c[0]
            if (w - CLUSTER_DISTANCE <= p[0] <= e + CLUSTER_DISTANCE
                    and s - CLUSTER_DISTANCE <= p[1] <= n + CLUSTER_DISTANCE):
                c[1].append(p)
                c[0] = (min(w, p[0]), min(s, p[1]), max(e, p[0]), max(n, p[1]))
                break
        else:
            clusters.append([(p[0], p[1], p[0], p[1]), [p]])
    return [c[0] for c in clusters]


def _index_range(pts, b):
    idx = [i for i, p in enumerate(pts) if in_bbox(p, b)]
    return (idx[0], idx[-1]) if idx else None


def changed_regions(old_src, new_src, dataset=None):
    """変更前後のセグメントを比較して変更箇所の領域リストを返す

    セグメントは (start, end) で対応付ける。各領域は
      status: added | removed | modified
      label: 表示用の名前
      bbox: 余白込みの範囲 (west, south, east, north)
      new / old: 該当セグメントの座標リスト（無ければ None）
      new_range / old_range: bbox 内に入る座標のインデックス範囲（無ければ None）
    """
    old_segs = segments(old_src, dataset)
    new_segs = segments(new_src, dataset)
    matched = set()
    regions = []

    def match(seg):
        # 複線区間など同じ (start, end) のセグメントが複数あり得るため、
        # 未対応のもののうち座標が同一のものを優先し、無ければ同じ向き→逆向きの順で先頭を選ぶ
        key = (seg["start"], seg["end"])
        cands = [(i, s, False) for i, s in enumerate(old_segs) if (s["start"], s["end"]) == key]
        cands += [(i, s, True) for i, s in enumerate(old_segs)
                  if (s["end"], s["start"]) == key and s["start"] != s["end"]]
        cands = [c for c in cands if c[0] not in matched]
        for c in cands:
            if old_coords(c) == coords(seg):
                return c
        return cands[0] if cands else None

    def old_coords(hit):
        # 逆向きで対応付けた場合は新しい側の向きに揃える
        _, s, rev = hit
        return list(reversed(coords(s))) if rev else coords(s)

    def region(status, label, b, new_pts, old_pts):
        regions.append({
            "status": status,
            "label": label,
            "bbox": b,
            "new": new_pts,
            "old": old_pts,
            "new_range": _index_range(new_pts, b) if new_pts else None,
            "old_range": _index_range(old_pts, b) if old_pts else None,
        })

    def unchanged(seg):
        hit = match(seg)
        return hit is not None and old_coords(hit) == coords(seg)

    # 座標が同一のものを先に対応付けてから、残りを変更として対応付ける
    order = sorted(range(len(new_segs)), key=lambda i: 0 if unchanged(new_segs[i]) else 1)
    for i in order:
        seg = new_segs[i]
        new_pts = coords(seg)
        hit = match(seg)
        label = f"seg[{i}] {seg['start']} -> {seg['end']}"
        if not hit:
            region("added", label, pad_bbox(bbox(new_pts)), new_pts, None)
            continue
        matched.add(hit[0])
        old_pts = old_coords(hit)
        if new_pts == old_pts:
            continue
        old_set, new_set = set(old_pts), set(new_pts)
        diff = [p for p in new_pts if p not in old_set] + [p for p in old_pts if p not in new_set]
        if not diff:
            # 同じ点集合で順序だけ変わった場合
            diff = new_pts
        for b in _cluster(diff):
            region("modified", label, pad_bbox(b), new_pts, old_pts)

    for i, seg in enumerate(old_segs):
        if i not in matched:
            old_pts = coords(seg)
            region("removed", f"(old) seg[{i}] {seg['start']} -> {seg['end']}",
                   pad_bbox(bbox(old_pts)), None, old_pts)
    return regions
