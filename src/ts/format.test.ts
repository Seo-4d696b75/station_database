import { readCsvSafe, readJsonSafe } from "./io"
import { csvLine, jsonLineList } from "./model/line"
import { csvPrefecture } from "./model/prefecture"
import { csvStation, jsonStationList } from "./model/station"
import { getAssert } from "./validate/assert"
import { validateLine } from "./validate/line"
import { Station, validateStation } from "./validate/station"

const dataset = process.env.DATASET
if (dataset !== "main" && dataset !== "extra") {
  throw Error(`不明なデータセットの指定：${dataset}`)
}

const extra = dataset === "extra"

const stations: Station[] = []
const stationCodeMap = new Map<number, Station>()

describe(`${dataset}データセット`, () => {

  const dir = `out/${extra ? "extra" : "main"}`

  describe("駅データのフォーマット＆整合性確認", () => {
    test("station.csv", () => {
      const file = `${dir}/station.csv`
      const list = readCsvSafe(file, csvStation)
      // 駅集合に対する検査
      const idSet = new Set<string>()
      const posSet = new Set<string>()
      const nameMap = new Map<string, Station>()
      const prefectureCnt: number[] = Array(48).fill(0)
      const duplicatedName = new Map<string, Station[]>()
      list.forEach((csv, i) => {
        const s: Station = {
          ...csv,
          impl: csv.impl === undefined || csv.impl
        }
        const assert = getAssert(`station.csv line:${i}`, s)
        // extra　の整合性
        assert(extra || csv.impl === undefined, "extra==falseの場合はimpl==undefined")
        assert(!extra || csv.impl !== undefined, "extra==trueの場合はimpl!=undefined")

        validateStation(s, assert, extra)
        // IDは重複ない
        assert(!idSet.has(s.id), "idが重複")
        idSet.add(s.id)
        // codeの重複なし
        assert(!stationCodeMap.has(s.code), "code重複")
        stationCodeMap.set(s.code, s)
        // nameの重複なし
        assert(!nameMap.has(s.name), "駅名の重複")
        nameMap.set(s.name, s)
        // 座標点の重複なし
        const pos = `${s.lat.toFixed(6)}/${s.lng.toFixed(6)}`
        assert(!posSet.has(pos), "駅座標の重複")
        posSet.add(pos)
        if (s.impl) {
          // 都道府県ごとの駅数を集計（駅メモ実装のみ）
          prefectureCnt[s.prefecture] += 1
        }
        if (s.name !== s.original_name) {
          // 駅名重複の検査
          duplicatedName.set(s.original_name, [
            s,
            ...duplicatedName.get(s.original_name) ?? []
          ])
        }
      })

      // 都道府県ごとの駅数を確認
      let assert = getAssert("prefecture.csv")
      readCsvSafe("src/check/prefecture.csv", csvPrefecture).forEach(p => {
        const actual = prefectureCnt[p.code]
        const expected = p.size
        assert(actual === expected, `${p.name} > 実装駅数が不一致 actual:${actual} expected:${expected}`)
      })
      // 駅名重複の確認
      assert = getAssert("駅名重複の確認")
      duplicatedName.forEach((stations, original) => {
        const s = nameMap.get(original)
        if (s) {
          // 駅メモ実装の場合はextraの駅との駅名重複でも駅名を修正しない
          assert(s.impl)
          // 逆に、originalとnameを別に命名している駅はextra
          assert(stations.filter(s => s.impl).length === 0)
        } else {
          // 重複がある場合はnameに区別の接尾語がつくのでname !== original
          assert(stations.length > 1)
        }
      })
    })
    test("station.json", () => {
      const file = `${dir}/station.json`
      readJsonSafe(file, jsonStationList).forEach((json, i) => {
        const s: Station = {
          ...json,
          open_date: json.open_date ?? null,
          closed_date: json.closed_date ?? null,
          impl: json.impl === undefined || json.impl,
          attr: json.attr ?? null,
        }
        const assert = getAssert(`station.json root[${i}]`, s)

        // extra　の整合性
        assert(extra || json.impl === undefined, "extra==falseの場合はimpl==undefined")
        assert(!extra || json.impl !== undefined, "extra==trueの場合はimpl!=undefined")
        validateStation(s, assert, extra)

        // 同一駅が存在するか
        const csv = stationCodeMap.get(s.code)
        assert(csv, "同一駅が.csvに見つからない")
        expect(s).toMatchObject(csv as any)
      })
    })
    test("line.csv", () => {
      const file = `${dir}/line.csv`
      readCsvSafe(file, csvLine).forEach((line, i) => {
        const assert = getAssert(`line.csv line:${i}`, line)
        validateLine(line, assert, extra)
      })
    })
    test("line.json", () => {
      const file = `${dir}/line.json`
      readJsonSafe(file, jsonLineList).forEach((line, i) => {
        const assert = getAssert(`line.json root[${i}]`, line)
        validateLine(line, assert, extra)
      })
    })
  })
})