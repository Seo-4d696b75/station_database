#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["staticmap==0.5.7"]
# ///
"""路線ポリラインを地理院タイル上に描画して PNG を出力する（src は読み取りのみ）

usage:
  uv run --script .claude/skills/station-polyline/scripts/render_polyline.py \\
      <code|路線名> --out <DIR> [--base REV] [--dataset main|extra] [--size WxH]

  --out      PNG の出力先ディレクトリ（リポジトリ外を推奨）
  --base     変更前として比較する git リビジョン（既定: HEAD）
  --dataset  main なら build と同様に extra セグメントを除外（既定: 全セグメント）
  --size     画像サイズ（既定: 1200x900）

出力:
  overview.png     路線全体
  region_NN.png    変更箇所ごとの拡大図（変更が無ければ出力しない）

凡例: 灰・太線 = 変更前 / 赤・細線 = 変更後 / 青点 = 登録駅
変更の無い区間は「灰の縁取り付きの赤線」、削除された区間は灰のみ、追加された区間は赤のみで見える。
背景: 地理院タイル（淡色地図）出典：国土地理院
"""
import math
import os
import sys

sys.dont_write_bytecode = True  # skills 配下に __pycache__ を作らない
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from polyline_lib import changed_regions, coords, find_line, line_stations, load_lines, load_src, segments  # noqa: E402

from PIL import ImageDraw  # noqa: E402
from staticmap import CircleMarker, Line, StaticMap  # noqa: E402

TILE_URL = "https://cyberjapandata.gsi.go.jp/xyz/pale/{z}/{x}/{y}.png"
MAX_ZOOM = 17  # 淡色地図の提供範囲は z18 まで。拡大し過ぎても情報が増えないので抑える
MIN_ZOOM = 5
PADDING = 40
MAX_REGIONS = 12

COLOR_OLD = "#8c8c8c"
COLOR_NEW = "#e60012"
COLOR_STATION = "#0050ff"


def mercator_y(lat):
    r = math.radians(lat)
    return (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2


def fit_zoom(b, width, height):
    w, s, e, n = b
    dx = max((e - w) / 360, 1e-9)
    dy = max(abs(mercator_y(s) - mercator_y(n)), 1e-9)
    z = math.floor(min(
        math.log2((width - 2 * PADDING) / (256 * dx)),
        math.log2((height - 2 * PADDING) / (256 * dy)),
    ))
    return max(MIN_ZOOM, min(MAX_ZOOM, z))


def new_map(width, height, old_src, new_src, dataset, stations):
    m = StaticMap(width, height, padding_x=PADDING, padding_y=PADDING, url_template=TILE_URL,
                  headers={"User-Agent": "station_database polyline review"})
    for seg in segments(old_src, dataset):
        m.add_line(Line(coords(seg), COLOR_OLD, 7))
    for seg in segments(new_src, dataset):
        m.add_line(Line(coords(seg), COLOR_NEW, 3))
    for st in stations:
        m.add_marker(CircleMarker((float(st["lng"]), float(st["lat"])), "white", 9))
        m.add_marker(CircleMarker((float(st["lng"]), float(st["lat"])), COLOR_STATION, 6))
    return m


def annotate(image, title):
    # PIL 既定フォントは日本語を描画できないため ASCII のみ
    lines = [
        title,
        "gray(thick): before / red(thin): after / blue: stations",
        "Map tiles: GSI Japan (cyberjapandata.gsi.go.jp)",
    ]
    draw = ImageDraw.Draw(image)
    y = image.height - 14 * len(lines) - 8
    draw.rectangle([0, y - 4, 420, image.height], fill="white")
    for i, text in enumerate(lines):
        draw.text((6, y + 14 * i), text, fill="black")
    return image


def main():
    args = sys.argv[1:]
    opts = {"--out": None, "--base": "HEAD", "--dataset": None, "--size": "1200x900"}
    for key in opts:
        if key in args:
            i = args.index(key)
            opts[key] = args[i + 1]
            del args[i:i + 2]
    if len(args) != 1 or not opts["--out"]:
        sys.exit(__doc__)

    width, height = (int(v) for v in opts["--size"].split("x"))
    dataset = opts["--dataset"]
    line = find_line(load_lines(), args[0])
    new_src = load_src(line["code"])
    old_src = load_src(line["code"], opts["--base"])
    if new_src is None and old_src is None:
        sys.exit(f"src/polyline/{line['code']}.json がありません")
    stations = [s for s in line_stations(line["code"]) if not (dataset == "main" and s["extra"] == "1")]
    os.makedirs(opts["--out"], exist_ok=True)

    title = f"{line['code']} base={opts['--base']}"
    path = os.path.join(opts["--out"], "overview.png")
    image = new_map(width, height, old_src, new_src, dataset, stations).render()
    annotate(image, f"{title} overview").save(path)
    print(f"{path}  {line['name']} 全体")

    regions = changed_regions(old_src, new_src, dataset)
    if not regions:
        print("変更箇所なし（--base と比較して差分が無い）")
    if len(regions) > MAX_REGIONS:
        print(f"変更箇所が {len(regions)} 件あるため先頭 {MAX_REGIONS} 件のみ出力")
    for n, r in enumerate(regions[:MAX_REGIONS], 1):
        w, s, e, nn = r["bbox"]
        center = ((w + e) / 2, (s + nn) / 2)
        zoom = fit_zoom(r["bbox"], width, height)
        image = new_map(width, height, old_src, new_src, dataset, stations).render(zoom=zoom, center=center)
        path = os.path.join(opts["--out"], f"region_{n:02d}.png")
        annotate(image, f"{title} region {n:02d} z{zoom} {r['status']}").save(path)
        print(f"{path}  [{r['status']}] {r['label']}  center=({center[0]:.5f}, {center[1]:.5f}) z{zoom}")


if __name__ == "__main__":
    main()
