import { CSVLine, JSONLine } from "../model/line"
import { Assert, assertEach } from "./assert"
import { assertObjectPartialMatched, assertObjectSetPartialMatched } from "./set"

/**
 * JSON, CSV のデータ形式に依存する差分を吸収する
 */
export interface Line {
  code: number
  id: string
  name: string
  name_kana: string
  name_formal: string | null
  station_size: number
  company_code: number | null
  color: string | null
  symbol: string | null
  closed: boolean
  closed_date: string | null
  extra: boolean
}

export function normalizeJSONLine(json: JSONLine): Line {
  return {
    ...json,
    name_formal: json.name_formal ?? null,
    company_code: json.company_code ?? null,
    color: json.color ?? null,
    symbol: json.symbol ?? null,
    closed_date: json.closed_date ?? null,
    extra: !!json.extra,
  }
}

export function normalizeCSVLine(csv: CSVLine): Line {
  return {
    ...csv,
    extra: !!csv.extra,
  }
}

// TODO id独自定義 => 公式定義への移行
// 移行後を見越して駅・路線ごとにid重複確認を分離している
export function validateLines(lines: Line[], where: string, extra: boolean) {
  const ids = new Set<string>()
  const codes = new Set<number>()
  const names = new Set<string>()
  assertEach(lines, where, (line, assert) => {
    assert(!ids.has(line.id), "idが重複")
    ids.add(line.id)
    assert(!codes.has(line.code), "路線codeが重複")
    codes.add(line.code)
    assert(!names.has(line.name), "路線名が重複")
    names.add(line.name)

    assert(extra || !line.extra, "mainデータセットの場合はextra==false")
    assert(line.closed || !line.closed_date, "現役路線に廃止日は設定できません")
    // 一部貨路線は現役だけど旅客路線としては廃線などの場合あり
    // TODO 廃線の定義が曖昧
    //assert(line.impl || line.closed, "impl==falseの場合はclosed==true")
  })
}

const keys: ReadonlyArray<keyof Line> = ["code", "id", "name", "name_kana", "name_formal", "station_size", "company_code", "color", "symbol", "closed", "closed_date", "extra"]

export function assertLineSetMatched(target: Line[], reference: Map<number, Line>) {
  assertObjectSetPartialMatched(target, reference, keys)
}

export function assertLineMatched(target: Line, reference: Line | undefined, assert: Assert) {
  assertObjectPartialMatched(target, reference, keys, assert)
}
