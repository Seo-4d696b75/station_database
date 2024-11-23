import { existsSync } from "fs"
import glob from "glob"
import { readCsvSafe, readJsonSafe } from "./io"
import { jsonDelaunayList } from "./model/delaunay"
import { jsonPolyline } from "./model/geo"
import { csvLine, jsonLineList, normalizeLine } from "./model/line"
import { jsonLineDetail } from "./model/lineDetail"
import { csvLineStationSize } from "./model/lineStationSize"
import { csvPolylineIgnore } from "./model/polylineIgnore"
import { csvPrefecture } from "./model/prefecture"
import { StationRegister, csvRegister } from "./model/register"
import { csvStation, jsonStationList, normalizeStation } from "./model/station"
import { jsonKdTree, jsonKdTreeSegment } from "./model/tree"
import { eachAssert, withAssert } from "./validate/assert"
import { validateGeoPolyline, validateGeoVoronoi } from "./validate/geo"
import { Line, assertLineMatched, assertLineSetMatched, validateLine } from "./validate/line"
import { assertObjectSetPartialMatched } from "./validate/set"
import { Station, assertStationMatched, assertStationSetMatched, validateStation } from "./validate/station"
import { validateTreeSegment } from "./validate/tree"

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

  // 各テストケースは逐次実行する必要がある
  describe("駅データのフォーマット＆整合性確認", () => {

    test("line.csv", () => {
      const file = `${dir}/line.csv`
      const nameSet = new Set<string>()
      readCsvSafe(file, csvLine).forEach(eachAssert("root", (csv, assert) => {
        const line: Line = {
          ...csv,
          extra: !!csv.extra,
        }

        // 各路線の検査
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

      // 駅集合に対する検査用
      const posSet = new Set<string>()
      const nameMap = new Map<string, Station>()
      const prefectureCnt: number[] = Array(48).fill(0)
      const duplicatedName = new Map<string, Station[]>()

      list.forEach(eachAssert("root", (csv, assert) => {
        const s: Station = {
          ...csv,
          extra: !!csv.extra,
        }

        // 各駅の検査
        validateStation(s, assert, extra)

        // 駅集合に対する検査
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

        if (!s.extra) {
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
            // extraデータセットのみ発生する
            assert(extra)
            // 駅メモ実装の場合はextraの駅との駅名重複でも駅名を修正しない
            assert(!s.extra)
            // 逆に、originalとnameを別に命名している駅はextra
            assert(stations.filter(s => !s.extra).length === 0)
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

        // 各路線の検査
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

        // 各駅の検査
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
        validateGeoVoronoi(json.voronoi)
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
      })
      test("各ファイルの確認", () => {
        // 各路線の登録駅数（駅メモ実装のみ）
        const lineStationSize = new Map<string, number>()
        readCsvSafe("src/check/line.csv", csvLineStationSize).forEach(e => {
          lineStationSize.set(e.name, e.size)
        })
        Array.from(lineCodemap.keys()).forEach(eachAssert(`lineMap.keys`, (code, assert) => {
          const file = `${dir}/line/${code}.json`
          assert(existsSync(file), "路線ファイルが見つからない file:" + file)
          const json = readJsonSafe(file, jsonLineDetail)
          // 対応路線の確認
          const line = normalizeLine(json)
          const csv = lineCodemap.get(line.code)
          assertLineMatched(line, csv, assert)
          // 駅リストの確認
          assert(json.station_size === json.station_list.length, "station_sizeとstation_list.length不一致")
          const registrations = stationRegister.filter(r => r.line_code === json.code)
          assert(registrations.length === json.station_size, "駅リストのサイズがregister.csvと異なる")
          const set = new Set<number>()
          let implSize = 0
          json.station_list.forEach(eachAssert("station_list", (s, assert, idx) => {
            assert(!set.has(s.code), "駅が重複")
            set.add(s.code)
            const station = normalizeStation(s)
            assertStationMatched(station, stationCodeMap.get(s.code), assert)

            // 対応する駅登録があるか
            const registration = registrations.find(r => r.station_code === station.code)
            assert(registration, "対応する駅登録がCSVにない")
            if (!registration) throw Error()

            withAssert("register.csv", registration, assert => {
              // 駅登録の順序
              // TODO mainデータセットの場合、check.rbでextraを飛ばしてindexをカウントしている
              assert.equals(idx + 1, registration.index, "駅の登録順が異なる")
              // 駅ナンバリング
              let numbering = s.numbering ? s.numbering.join("/") : null
              assert.equals(numbering, registration.numbering, "駅ナンバリングが異なる")
              // 駅メモ実装での登録駅数をカウント
              // 注意： extraの意味の対象が異なる！
              // line/*.json .station_list[].extra: 駅自体
              // register.csv: 路線に対する駅登録
              if (!registration.extra) {
                implSize++
              }
            })
          }))

          // 駅メモ実装路線の場合は登録駅数が別途定義されている
          assert(line.extra || lineStationSize.has(line.name), "路線の登録駅数（駅メモ実装）が見つからない")

          // extra路線における駅メモ実装の登録液数は0
          const expected = lineStationSize.get(line.name) ?? 0
          assert.equals(implSize, expected, "路線の登録駅数（駅メモ）が異なる")

        }))
      })
    })

    describe("polyline/*.json", () => {

      // polyline未定義を許す路線一覧
      const polylineIgnore = readCsvSafe("src/check/polyline_ignore.csv", csvPolylineIgnore).map(e => e.name)

      test("ファイルの有無確認", () => {
        const files = glob.sync(`${dir}/polyline/*.json`)
        expect(files.length).toBe(lineCodemap.size - polylineIgnore.length)
      })

      test("各ファイルの確認", () => {
        Array.from(lineCodemap.values()).forEach(eachAssert("lineMap.keys", (line, assert) => {
          if (polylineIgnore.includes(line.name)) {
            return
          }
          const file = `${dir}/polyline/${line.code}.json`
          assert(existsSync(file), "ポリラインファイルが見つからない file:" + file)
          const json = readJsonSafe(file, jsonPolyline)
          validateGeoPolyline(json)
        }))
      })
    })

    describe("KdTree", () => {
      test("tree.json", () => {
        const file = `${dir}/tree.json`
        const tree = readJsonSafe(file, jsonKdTree)
        withAssert("tree.json", tree, assert => {
          validateTreeSegment(tree, assert)
          assertObjectSetPartialMatched(tree.node_list, stationCodeMap, ["code", "name", "lat", "lng"])
        })
      })
      describe("segment", () => {
        const files = glob.sync(`${dir}/tree/*.json`)
        const rootFile = `${dir}/tree/root.json`
        test("ファイルの確認", () => {
          withAssert("tree/*.json", files, assert => {
            const idx = files.indexOf(rootFile)
            assert(idx >= 0, "root.jsonが見つからない")
            files.splice(idx, 1)
            files.forEach(eachAssert("files", (file, assert) => {
              const m = file.match(/\/segment[0-9]+[.]json$/)
              assert(m, "segmentファイル名が不正 file:" + file)
            }))
          })
        })
        test("各ファイルの確認", () => {
          const list: Station[] = []
          const segmentMap = new Map<string, number>()
          files.forEach(eachAssert("files", (file, assert) => {
            const segment = readJsonSafe(file, jsonKdTreeSegment)
            assert(!segmentMap.has(segment.name), "segment-name重複している")
            segmentMap.set(segment.name, segment.root)
            segment.node_list.forEach(eachAssert("node_list", (node, assert) => {
              assert(!node.segment, "segmentの分割はrootのみ")
              list.push(normalizeStation(node))
            }))
            validateTreeSegment(segment, assert)
          }))
          withAssert("root", rootFile, assert => {
            const root = readJsonSafe(rootFile, jsonKdTreeSegment)
            assert.equals(root.name, "root")
            root.node_list.filter(node => !node.segment).forEach(node => {
              list.push(normalizeStation(node))
            })
            validateTreeSegment(root, assert)
            const segments = root.node_list.filter(node => node.segment)
            assert.equals(segments.length, segmentMap.size, "segmentサイズが一致しない")
            segments.forEach(eachAssert("segments", (node, assert) => {
              const name = node.segment ?? ""
              assert(segmentMap.has(name), "segmentが見つからない")
              const code = segmentMap.get(name)
              assert.equals(code, node.code, "segmentのrootが一致しない")
            }))
          })
          assertStationSetMatched(list, stationCodeMap)
        })
      })
    })
  })
})