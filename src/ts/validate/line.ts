import { Assert } from "./assert"

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
  impl: boolean
}

export function validateLine(line: Line, assert: Assert, extra: boolean) {

  assert(extra || line.impl, "extra==falseの場合はimpl==true")

  assert(line.closed || !line.closed_date, "現役路線に廃止日は設定できません")
  // 一部貨路線は現役だけど旅客路線としては廃線などの場合あり
  // TODO 廃線の定義が曖昧
  //assert(line.impl || line.closed, "impl==falseの場合はclosed==true")

}