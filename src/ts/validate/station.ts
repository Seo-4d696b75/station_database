import { Assert } from "./assert"
import { assertObjectPartialMatched, assertObjectSetPartialMatched } from "./set"

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
  open_date: string | null
  closed_date: string | null
  extra: boolean
  attr: string | null
}

export function validateStation(s: Station, assert: Assert, extra: boolean) {

  assert(extra || !s.extra, "mainデータセットの場合はextra==false")

  // attr 整合性
  assert(s.extra || s.attr, "extra==falseの場合はattr!=null")
  assert(!s.extra || !s.attr, "extra==trueの場合はattr==null")
  // 一部貨物駅は現役だけど旅客駅としては廃駅などの場合あり
  // TODO 廃駅の定義が曖昧
  //assert(!s.extra || s.closed, "extra==trueの場合はclosed==true")
  assert(s.extra || s.closed === (s.attr === "unknown"), "extra==falseの場合は廃駅の属性はunknown")

  // date の整合性
  if (s.open_date && s.closed_date) {
    assert(s.open_date < s.closed_date, "開業日＜廃止日")
  }
  assert(s.closed || !s.closed_date, "現役駅に廃止日は設定できません")

  // nameの整合性
  assert(s.name === s.original_name || s.name.includes(s.original_name), "駅名originalはsubstring")

  // lat,lng 小数点以下桁数
  let lat = s.lat * Math.pow(10, 6)
  assert(Math.abs(lat - Math.round(lat)) < 0.0001)
  let lng = s.lng * Math.pow(10, 6)
  assert(Math.abs(lng - Math.round(lng)) < 0.0001)
}

const keys: ReadonlyArray<keyof Station> = ["code", "id", "name", "name_kana", "original_name", "lat", "lng", "prefecture", "postal_code", "address", "closed", "open_date", "closed_date", "extra", "attr"]

export function assertStationSetMatched(target: Station[], reference: Map<number, Station>) {
  assertObjectSetPartialMatched(target, reference, keys)
}

export function assertStationMatched(target: Station, reference: Station | undefined, assert: Assert) {
  assertObjectPartialMatched(target, reference, keys, assert)
}