import { readCsvSafe, readJsonSafe } from "./io"
import { jsonDelaunayList } from "./model/delaunay"
import { csvLine, jsonLineList, normalizeLine } from "./model/line"
import { csvPrefecture } from "./model/prefecture"
import { csvRegister, StationRegister } from "./model/register"
import { csvStation, jsonStationList, normalizeStation } from "./model/station"
import { eachAssert, withAssert } from "./validate/assert"
import { assertLineMatched, assertLineSetMatched, Line, validateLine } from "./validate/line"
import { assertStationMatched, assertStationSetMatched, Station, validateStation } from "./validate/station"
import glob from "glob";
import { assertObjectSetPartialMatched } from "./validate/set"
import { jsonLineDetail } from "./model/lineDetail"
import { csvPolylineIgnore } from "./model/polylineIgnore"
import { csvLineStationSize } from "./model/lineStationSize"
import { validateGeoFeature, validateGeoPolyline } from "./validate/geo"

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
      const list = readJsonSafe(file, jsonLineList).map(eachAssert("root", (json, assert) => {
        const line = normalizeLine(json)
        // extra　の整合性
        assert(extra || json.impl === undefined, "extra==falseの場合はimpl==undefined")
        assert(!extra || json.impl !== undefined, "extra==trueの場合はimpl!=undefined")
        validateLine(line, assert, extra)

        return line
      }))
      // 同一路線が存在するか
      assertLineSetMatched(list, lineCodemap)
    })
    test("station.json", () => {
      const file = `${dir}/station.json`
      const list = readJsonSafe(file, jsonStationList).map(eachAssert("root", (json, assert) => {
        const s = normalizeStation(json)

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
        // ボロノイ範囲のGeoJSON
        validateGeoFeature(json.voronoi)
        return s
      }))
      // 同一駅が存在するか
      assertStationSetMatched(list, stationCodeMap)
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
      assertObjectSetPartialMatched(list, stationCodeMap, ["code", "name", "lat", "lng"])
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
      test("各ファイルの確認", () => {
        // polyline未定義を許す路線一覧
        const polylineIgnore = readCsvSafe("src/check/polyline_ignore.csv", csvPolylineIgnore).map(e => e.name)
        // 各路線の登録駅数（駅メモ実装のみ）
        const lineStationSize = new Map<string, number>()
        readCsvSafe("src/check/line.csv", csvLineStationSize).forEach(e => {
          lineStationSize.set(e.name, e.size)
        })
        Array.from(lineCodemap.keys()).forEach(eachAssert(`lineMap.keys`, (code, assert) => {
          const file = `${dir}/line/${code}.json`
          const json = readJsonSafe(file, jsonLineDetail)
          // 対応路線の確認
          const line = normalizeLine(json)
          const csv = lineCodemap.get(line.code)
          assertLineMatched(line, csv, assert)
          // ポリラインの確認
          assert(json.polyline_list || polylineIgnore.includes(json.name), "ポリラインの欠損が許されていない")
          if (json.polyline_list) {
            assert.equals(json.polyline_list.properties.name, json.name)
            validateGeoPolyline(json.polyline_list)
          }
          // 駅リストの確認
          assert(json.station_size === json.station_list.length, "station_sizeとstation_list.length不一致")
          const registrations = stationRegister.filter(r => r.line_code === json.code)
          assert(registrations.length === json.station_size, "駅リストのサイズがregister.csvと異なる")
          const set = new Set<number>()
          let implSize = 0
          json.station_list.forEach(eachAssert("station_list", (s, assert) => {
            assert(!set.has(s.code), "駅が重複")
            set.add(s.code)
            const station = normalizeStation(s)
            assertStationMatched(station, stationCodeMap.get(s.code), assert)
            if (station.impl) {
              implSize++
            }
            // 対応する駅登録があるか
            const registration = registrations.find(r => r.station_code === station.code)
            assert(registration, "対応する駅登録がCSVにない")
            if (!registration) throw Error()
            withAssert("register.csv", registration, assert => {
              // 駅ナンバリング
              let numbering = s.numbering ? s.numbering.join("/") : null
              assert.equals(numbering, registration.numbering, "駅ナンバリングが異なる")
            })
          }))
          if (!extra) {
            // 登録駅数の確認
            // extraデータセットでは確認しない
            // https://github.com/Seo-4d696b75/station_database/issues/72
            assert(lineStationSize.has(line.name), "路線の登録駅数（実装のみ）が見つからない")
            const expected = lineStationSize.get(line.name) ?? 0
            assert.equals(implSize, expected, "路線の登録駅数（実装のみ）が異なる")
          }
        }))
      })
    })
  })
})