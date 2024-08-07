import { Assert } from "./assert"
import { assertObjectPartialMatched, assertObjectSetPartialMatched } from "./set"

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

export function validateLine(line: Line, assert: Assert, extra: boolean) {

  assert(extra || !line.extra, "mainデータセットの場合はextra==false")

  assert(line.closed || !line.closed_date, "現役路線に廃止日は設定できません")
  // 一部貨路線は現役だけど旅客路線としては廃線などの場合あり
  // TODO 廃線の定義が曖昧
  //assert(line.impl || line.closed, "impl==falseの場合はclosed==true")

}

const keys: ReadonlyArray<keyof Line> = ["code", "id", "name", "name_kana", "name_formal", "station_size", "company_code", "color", "symbol", "closed", "closed_date", "extra"]

export function assertLineSetMatched(target: Line[], reference: Map<number, Line>) {
  assertObjectSetPartialMatched(target, reference, keys)
}

export function assertLineMatched(target: Line, reference: Line | undefined, assert: Assert) {
  assertObjectPartialMatched(target, reference, keys, assert)
}
