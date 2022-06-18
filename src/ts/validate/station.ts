import { Assert } from "./assert"

export interface Station {
  code: number
  id: string
  name: string
  original_name: string
  name_kana: string
  lat: number
  lng: number
  prefecture: number
  postal_code: string
  address: string
  closed: boolean
  open_date?: string | null
  closed_date?: string | null
  impl?: boolean
  attr?: string | null
}

export function validateStation(s: Station, assert: Assert, extra: boolean) {
  const impl = (s.impl === undefined || s.impl)
  // extra　の整合性
  assert(extra || s.impl === undefined, "extra==falseの場合はimpl==undefined")
  assert(!extra || s.impl !== undefined, "extra==trueの場合はimpl!=undefined")

  assert(extra || impl, "extra==falseの場合はimpl==true")

  // attr 整合性
  assert(!impl || s.attr, "impl==trueの場合はattr!=null")
  assert(impl || !s.attr, "impl==falseの場合はattr==null")
  // 一部貨物駅は現役だけど旅客駅としては廃駅などの場合あり
  // TODO 廃駅の定義が曖昧
  //assert(impl || s.closed, "impl==falseの場合はclosed==true")
  assert(!impl || s.closed === (s.attr === "unknown"), "impl==true, 廃駅の属性はunknown")


  // date の整合性
  if (s.open_date && s.closed_date) {
    assert(s.open_date < s.closed_date, "開業日＜廃止日")
  }
  assert(s.closed || !s.closed_date, "現役駅に廃止日は設定できません")

  // nameの整合性
  assert(s.name === s.original_name || s.name.includes(s.original_name), "駅名originalはsubstring")
}