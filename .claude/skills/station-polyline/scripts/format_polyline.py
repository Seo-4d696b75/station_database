#!/usr/bin/env python3
"""src/polyline/{code}.json を規定の書式に整形する

usage:
  python3 -I .claude/skills/station-polyline/scripts/format_polyline.py <code|路線名|path> [...] [--check]

  --check  書き換えずに、書式に従っていないファイルを表示して終了コード 1 を返す

書式:
  - 2 space indent の一般的な pretty format（"key": value）
  - 座標点のみ1行・空白なし・lat, lng の順: {"lat":42.9399,"lng":142.03949}
  - 数値は元の表記（末尾の0など）をそのまま保つ。キーの順序も座標点以外は保つ
  - 末尾に改行
"""
import json
import os
import sys
from decimal import Decimal

sys.dont_write_bytecode = True  # skills 配下に __pycache__ を作らない
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from polyline_lib import find_line, load_lines  # noqa: E402

INDENT = "  "


def dump(value, depth=0):
    pad = INDENT * (depth + 1)
    end = INDENT * depth
    if isinstance(value, dict):
        if set(value) == {"lat", "lng"}:
            return f'{{"lat":{dump(value["lat"])},"lng":{dump(value["lng"])}}}'
        if not value:
            return "{}"
        items = [f"{pad}{json.dumps(k, ensure_ascii=False)}: {dump(v, depth + 1)}" for k, v in value.items()]
        return "{\n" + ",\n".join(items) + "\n" + end + "}"
    if isinstance(value, list):
        if not value:
            return "[]"
        return "[\n" + ",\n".join(pad + dump(v, depth + 1) for v in value) + "\n" + end + "]"
    if isinstance(value, Decimal):
        return str(value)
    return json.dumps(value, ensure_ascii=False)


def resolve(lines, key):
    if os.path.exists(key):
        return key
    return f"src/polyline/{find_line(lines, key)['code']}.json"


def main():
    args = sys.argv[1:]
    check = "--check" in args
    args = [a for a in args if a != "--check"]
    if not args:
        sys.exit(__doc__)

    lines = load_lines()
    unformatted = []
    for path in (resolve(lines, a) for a in args):
        with open(path, encoding="utf-8") as f:
            text = f.read()
        data = json.loads(text, parse_float=Decimal)
        formatted = dump(data) + "\n"
        # 整形前後で内容が変わっていないこと
        assert json.loads(formatted, parse_float=Decimal) == data, path
        if formatted == text:
            continue
        unformatted.append(path)
        if not check:
            with open(path, "w", encoding="utf-8") as f:
                f.write(formatted)
            print(f"formatted: {path}")

    if check and unformatted:
        for path in unformatted:
            print(f"unformatted: {path}")
        sys.exit(1)


if __name__ == "__main__":
    main()
