import { readCsvSafe, readJsonSafe } from "./io"
import { jsonDelaunayList } from "./model/delaunay"
import { csvLine, jsonLineList } from "./model/line"
import { csvPrefecture } from "./model/prefecture"
import { csvRegister, StationRegister } from "./model/register"
import { csvStation, jsonStationList } from "./model/station"
import { eachAssert, withAssert } from "./validate/assert"
import { Line, validateLine } from "./validate/line"
import { isStationSetMatched, isStationSetPartialMatched, Station, validateStation } from "./validate/station"
import glob from "glob";

const dataset = process.env.DATASET
if (dataset !== "main" && dataset !== "extra") {
  throw Error(`不明なデータセットの指定：${dataset}`)
}

const extra = dataset === "extra"

const stationCodeMap = new Map<number, Station>()
const lineCodemap = new Map<number, Line>()
const stationRegister: StationRegister[] = []
const idSet = new Set<string>()

describe(`${dataset}データセット`, () => {

  const dir = `out/${extra ? "extra" : "main"}`

  describe("駅データのフォーマット＆整合性確認", () => {

    test("line.csv", () => {
      const file = `${dir}/line.csv`
      const nameSet = new Set<string>()
      readCsvSafe(file, csvLine).forEach(eachAssert("root", (csv, assert) => {
        const line: Line = {
          ...csv,
          impl: csv.impl === undefined || csv.impl
        }

        // extra　の整合性
        assert(extra || csv.impl === undefined, "extra==falseの場合はimpl==undefined")
        assert(!extra || csv.impl !== undefined, "extra==trueの場合はimpl!=undefined")
        validateLine(line, assert, extra)
        // 路線集合に対する検査
        // IDは重複ない
        assert(!idSet.has(line.id), "idが重複")
        idSet.add(line.id)
        // codeの重複なし
        assert(!lineCodemap.has(line.code), "code重複")
        lineCodemap.set(line.code, line)
        // nameの重複なし
        assert(!nameSet.has(line.name), "駅名の重複")
        nameSet.add(line.name)
      }))
    })
    test("station.csv", () => {
      const file = `${dir}/station.csv`
      const list = readCsvSafe(file, csvStation)
      // 駅集合に対する検査
      const posSet = new Set<string>()
      const nameMap = new Map<string, Station>()
      const prefectureCnt: number[] = Array(48).fill(0)
      const duplicatedName = new Map<string, Station[]>()
      list.forEach(eachAssert("root", (csv, assert) => {
        const s: Station = {
          ...csv,
          impl: csv.impl === undefined || csv.impl
        }
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
      }))

      // 都道府県ごとの駅数を確認
      readCsvSafe("src/check/prefecture.csv", csvPrefecture).forEach(eachAssert("prefecture.csv root", (p, assert) => {
        const actual = prefectureCnt[p.code]
        const expected = p.size
        assert(actual === expected, `${p.name} > 実装駅数が不一致 actual:${actual} expected:${expected}`)
      }))
      // 駅名重複の確認
      duplicatedName.forEach((stations, original) => {
        withAssert("駅名重複の確認", original, assert => {
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
    })

    test("register.csv", () => {
      const file = `${dir}/register.csv`
      readCsvSafe(file, csvRegister).forEach(eachAssert("root", (r, assert) => {
        assert(stationCodeMap.has(r.station_code), "駅コードが見つからない")
        assert(lineCodemap.has(r.line_code), "路線コードが見つからない")
        stationRegister.push(r)
      }))
    })

    test("line.json", () => {
      const file = `${dir}/line.json`
      readJsonSafe(file, jsonLineList).forEach(eachAssert("root", (json, assert) => {
        const line: Line = {
          ...json,
          name_formal: json.name_formal ?? null,
          company_code: json.company_code ?? null,
          color: json.color ?? null,
          symbol: json.symbol ?? null,
          closed_date: json.closed_date ?? null,
          impl: json.impl === undefined || json.impl
        }
        // extra　の整合性
        assert(extra || json.impl === undefined, "extra==falseの場合はimpl==undefined")
        assert(!extra || json.impl !== undefined, "extra==trueの場合はimpl!=undefined")
        validateLine(line, assert, extra)

        // 同一路線が存在するか
        const csv = lineCodemap.get(line.code)
        assert(csv, "同一路線が.csvに見つからない")
        expect(line).toMatchObject(csv ?? {})
      }))
    })
    test("station.json", () => {
      const file = `${dir}/station.json`
      const list = readJsonSafe(file, jsonStationList).map(eachAssert("root", (json, assert) => {
        const s: Station = {
          ...json,
          open_date: json.open_date ?? null,
          closed_date: json.closed_date ?? null,
          impl: json.impl === undefined || json.impl,
          attr: json.attr ?? null,
        }

        // extra　の整合性
        assert(extra || json.impl === undefined, "extra==falseの場合はimpl==undefined")
        assert(!extra || json.impl !== undefined, "extra==trueの場合はimpl!=undefined")
        validateStation(s, assert, extra)

        // 登録路線の確認
        const register = stationRegister.filter(r => r.station_code === s.code).map(r => r.line_code)
        assert(register.length === json.lines.length, "register.csvの登録路線数と異なる")
        json.lines.forEach(code => {
          assert(lineCodemap.has(code), "路線コードが見つからない" + code)
          assert(register.includes(code), "register.csvに路線コードが登録されていない：" + code)
        })
        if (!json.closed) {
          let len = json.lines.filter(code => lineCodemap.get(code)?.closed === false).length
          assert(len > 0, "現役駅は１つ以上の現役路線に登録が必要")
        }
        return s
      }))
      // 同一駅が存在するか
      //isStationSetMatched(list, stationCodeMap, getAssert("station.json"))
    })
    test("delaunay.json", () => {
      const file = `${dir}/delaunay.json`
      const list = readJsonSafe(file, jsonDelaunayList)
      list.forEach(eachAssert("root", s => {
        s.next.forEach(eachAssert("next", (code, assert) => {
          assert(code !== s.code, "自身の駅コードは隣接点に含まれない code:" + code)
          assert(stationCodeMap.has(code), "路線コードが見つからない" + code)
        }))
      }))
      //isStationSetPartialMatched(list, stationCodeMap, assert, ["code", "name", "lat", "lng"])
    })
    describe("line/*.json", () => {
      test("ファイルの有無確認", () => {
        const files = glob.sync(`${dir}/line/*.json`)
        // line/*.jsonのファイル数と路線数一致
        expect(files.length).toBe(lineCodemap.size)
        files.forEach(eachAssert("files", (file, assert) => {
          const m = file.match(/\/(?<code>[0-9]+)[.]json$/)
          assert(m, "路線ファイル名が不正 file:" + file)
          if (!m) throw Error()
          const code = Number(m.groups?.["code"] ?? "0")
          assert(lineCodemap.has(code), "路線ファイルに対応する路線コードが見つからない code:" + code)
        }))
      })
    })
  })
})