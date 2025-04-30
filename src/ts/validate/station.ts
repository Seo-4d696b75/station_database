import { readCsvSafe } from "../io"
import { Dataset, hasExtra } from "../model/dataset"
import { csvPrefecture } from "../model/prefecture"
import { CSVStation, JSONStation } from "../model/station"
import { Assert, assertEach } from "./assert"
import { assertObjectPartialMatched, assertObjectSetPartialMatched } from "./set"

/**
 * JSON, CSV のデータ形式に依存する差分を吸収する
 */
export interface Station {
  code: number
  id: number
  name: string
  original_name: string
  name_kana: string
  lat: number
  lng: number
  prefecture: number
  lines: number[]
  postal_code: string
  address: string
  closed: boolean
  open_date: string | null
  closed_date: string | null
  extra: boolean
  attr: string | null
}

export function normalizeJSONStation(json: JSONStation<Dataset>): Station {
  return {
    ...json,
    open_date: json.open_date ?? null,
    closed_date: json.closed_date ?? null,
    extra: hasExtra(json) ? json.extra : false,
    attr: json.attr ?? null,
  }
}

/**
 * 登録路線一覧 `line` は空リストで初期化
 */
export function normalizeCSVStation(csv: CSVStation<Dataset>): Station {
  return {
    ...csv,
    lines: [],
    extra: hasExtra(csv) ? csv.extra : false,
  }
}

// TODO id独自定義 => 公式定義への移行
// 移行後を見越して駅・路線ごとにid重複確認を分離している
export function validateStations(stations: Station[], where: string, extra: boolean) {
  const ids = new Set<number>()
  const codes = new Set<number>()
  const map = new Map<string, Station>()
  const coordinates = new Set<string>()
  const prefCount = new Array(48).fill(0)
  const duplicatedNameMap = new Map<string, Station[]>()

  assertEach(stations, where, (s, assert) => {
    assert(!ids.has(s.id), "idが重複")
    ids.add(s.id)
    assert(!codes.has(s.code), "駅コードが重複")
    codes.add(s.code)
    assert(!map.has(s.name), "駅名が重複")
    map.set(s.name, s)

    assert(extra || !s.extra, "mainデータセットの場合はextra==false")

    // attr 整合性
    assert(s.extra || s.attr, "extra==falseの駅の属性にnullは指定できません")
    assert(!s.extra || !s.attr, "extra駅の駅属性はnullです")
    // 一部貨物駅は現役だけど旅客駅としては廃駅などの場合あり
    // TODO 廃駅の定義が曖昧
    //assert(!s.extra || s.closed, "extra==trueの場合はclosed==true")
    assert(s.extra || s.closed === (s.attr === "unknown"), "廃駅(extra==false)の属性はunknown")

    // date の整合性
    if (s.open_date && s.closed_date) {
      assert(s.open_date < s.closed_date, "開業日＜廃止日")
    }
    assert(s.closed || !s.closed_date, "現役駅に廃止日は設定できません")

    // nameの整合性
    assert(s.name === s.original_name || s.name.includes(s.original_name), "original_nameはnameの部分文字列です")

    // lat,lng
    const pos = `${s.lng},${s.lat}`
    assert(!coordinates.has(pos), '駅の緯度・経度が重複')
    let lat = s.lat * Math.pow(10, 6)
    assert(Math.abs(lat - Math.round(lat)) < 0.0001)
    let lng = s.lng * Math.pow(10, 6)
    assert(Math.abs(lng - Math.round(lng)) < 0.0001)


    // 重複名称の記録
    if (s.name !== s.original_name) {
      const existing = duplicatedNameMap.get(s.original_name) || []
      duplicatedNameMap.set(s.original_name, [...existing, s])
    }

    // 都道府県ごとの集計
    if (!s.extra) {
      prefCount[s.prefecture]++
    }
  })

  // 駅名の重複チェック
  assertEach(duplicatedNameMap, '駅名(original)重複の確認', ([originalName, stations], assert) => {
    const baseStation = map.get(originalName)
    if (baseStation) {
      // 駅メモ実装の駅の場合
      assert(
        !baseStation.extra && stations.every(v => v.extra),
        `駅メモ実装の駅名には重複無し & extra駅の追加で駅名が重複する場合のみ、重複防止の接尾語が省略できます`
      )
    } else {
      assert(stations.length > 1, `駅名とは異なる駅名(original)が登録されていますが重複がありません`)
    }
  })

  // 都道府県ごとの駅数チェック
  assertEach(
    readCsvSafe('src/check/prefecture.csv', csvPrefecture),
    'prefecture.csv',
    (pref, assert) => {
      assert.equals(
        prefCount[pref.code],
        pref.size,
        `都道府県毎の駅数が異なります`
      )
    },
  )
}

const keys: ReadonlyArray<keyof Station> = ["code", "id", "name", "name_kana", "original_name", "lat", "lng", "prefecture", "postal_code", "address", "closed", "open_date", "closed_date", "extra", "attr"]

export function assertStationSetMatched(target: Station[], reference: Map<number, Station>) {
  assertObjectSetPartialMatched(target, reference, keys)
}

export function assertStationMatched(target: Station, reference: Station | undefined, assert: Assert) {
  assertObjectPartialMatched(target, reference, keys, assert)
}