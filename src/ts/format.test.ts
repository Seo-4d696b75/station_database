import { existsSync } from "fs"
import { globSync } from "glob"
import { readCsvSafe, readJsonSafe } from "./io"
import { hasExtra, parseDataset } from "./model/dataset"
import { jsonDelaunayList } from "./model/delaunay"
import { jsonPolyline } from "./model/geo"
import { csvLine, jsonLineList } from "./model/line"
import { jsonLineDetail } from "./model/lineDetail"
import { csvLineStationSize } from "./model/lineStationSize"
import { csvPolylineIgnore } from "./model/polylineIgnore"
import { CSVStationRegister, csvRegister } from "./model/register"
import { csvStation, jsonStationList, normalizeStation } from "./model/station"
import { jsonKdTree, jsonKdTreeSegment } from "./model/tree"
import { assertEach, assertEachAsync, withAssert } from "./validate/assert"
import { validateGeoPolyline, validateGeoVoronoi } from "./validate/geo"
import { Line, assertLineMatched, assertLineSetMatched, normalizeCSVLine, normalizeJSONLine, validateLines } from "./validate/line"
import { assertObjectSetPartialMatched } from "./validate/set"
import { Station, assertStationMatched, assertStationSetMatched, normalizeCSVStation, validateStations } from "./validate/station"
import { validateTreeSegment } from "./validate/tree"

const dataset = parseDataset(process.env.DATASET)
const extra = dataset === "extra"

const stationCodeMap = new Map<number, Station>()
const lineCodemap = new Map<number, Line>()
const stationRegister: CSVStationRegister<typeof dataset>[] = []

describe(`${dataset}データセット`, () => {

  const dir = `out/${extra ? "extra" : "main"}`

  // 各テストケースは逐次実行する必要がある
  describe("駅データのフォーマット＆整合性確認", () => {

    test("line.csv", () => {
      const file = `${dir}/line.csv`
      const lines = readCsvSafe(file, csvLine(dataset)).map(csv => normalizeCSVLine(csv))

      validateLines(lines, "line.csv", extra)
      lines.forEach(line => {
        lineCodemap.set(line.code, line)
      })
    })
    test("station.csv", () => {
      const file = `${dir}/station.csv`
      const stations = readCsvSafe(file, csvStation(dataset)).map(csv => normalizeCSVStation(csv))

      validateStations(stations, "station.csv", extra)
      stations.forEach(station => {
        stationCodeMap.set(station.code, station)
      })
    })

    test("register.csv", () => {
      const file = `${dir}/register.csv`
      assertEach(readCsvSafe(file, csvRegister(dataset)), "register.csv", (r, assert) => {
        assert(stationCodeMap.has(r.station_code), "駅コードが見つからない")
        assert(lineCodemap.has(r.line_code), "路線コードが見つからない")
        stationRegister.push(r)
      })
    })

    test("line.json", async () => {
      const file = `${dir}/line.json`
      const list = (await readJsonSafe(file, jsonLineList(dataset))).map(json => normalizeJSONLine(json))

      // 同一集合なら不用かも？
      validateLines(list, "line.json", extra)
      // 同一路線が存在するか
      assertLineSetMatched(list, lineCodemap)
    })
    test("station.json", async () => {
      const file = `${dir}/station.json`
      const stations = await readJsonSafe(file, jsonStationList(dataset))
      assertEach(stations, "station.json", (json, assert) => {
        // 登録路線の確認
        const register = stationRegister.filter(r => r.station_code === json.code).map(r => r.line_code)
        assert.equals(json.lines.length, register.length, "register.csvの登録路線数と異なる")
        assertEach(json.lines, ".lines", (code, assert) => {
          assert(lineCodemap.has(code), "路線コードが見つからない" + code)
          assert(register.includes(code), "register.csvに路線コードが登録されていない：" + code)
        })
        if (!json.closed) {
          const hasActiveLine = json.lines.some(code => {
            const line = lineCodemap.get(code)
            return line && !line.closed
          })
          assert(hasActiveLine, "現役駅は１つ以上の現役路線に登録が必要")
        }
        // ボロノイ範囲のGeoJSON
        validateGeoVoronoi(json.voronoi)
      })

      const list = stations.map(s => normalizeStation(s))
      // 同一集合なら不用かも？
      validateStations(list, "station.json", extra)
      // 同一駅が存在するか
      assertStationSetMatched(list, stationCodeMap)
    })
    test("delaunay.json", async () => {
      const file = `${dir}/delaunay.json`
      const list = await readJsonSafe(file, jsonDelaunayList)
      assertEach(list, "root", (s, assert) => {
        assertEach(s.next, "next", (code, assert) => {
          assert(code !== s.code, "自身の駅コードは隣接点に含まれない code:" + code)
          assert(stationCodeMap.has(code), "路線コードが見つからない" + code)
        })
      })
      assertObjectSetPartialMatched(list, stationCodeMap, ["code", "name", "lat", "lng"])
    })
    describe("line/*.json", () => {
      test("ファイルの有無確認", () => {
        const files = globSync(`${dir}/line/*.json`)
        // line/*.jsonのファイル数と路線数一致
        expect(files.length).toBe(lineCodemap.size)
      })
      test("各ファイルの確認", async () => {
        // 各路線の登録駅数（駅メモ実装のみ）
        const lineStationSize = new Map<string, number>()
        readCsvSafe("src/check/line.csv", csvLineStationSize).forEach(e => {
          lineStationSize.set(e.name, e.size)
        })
        const schema = jsonLineDetail(dataset)
        await assertEachAsync(lineCodemap.keys(), "lines", async (code, assert) => {
          const file = `${dir}/line/${code}.json`
          assert(existsSync(file), "路線ファイルが見つからない file:" + file)
          const json = await readJsonSafe(file, schema)
          // 対応路線の確認
          const line = normalizeJSONLine(json)
          const csv = lineCodemap.get(line.code)
          assertLineMatched(line, csv, assert)
          // 駅リストの確認
          assert.equals(json.station_size, json.station_list.length, "station_sizeとstation_list.length不一致")
          const registrations = stationRegister.filter(r => r.line_code === code)
          assert.equals(json.station_size, registrations.length, "駅リストのサイズがregister.csvと異なる")
          const set = new Set<number>()
          let implSize = 0
          assertEach(json.station_list, "station_list", (s, assert, idx) => {
            assert(!set.has(s.code), "駅が重複")
            set.add(s.code)
            const station = normalizeStation(s)
            assertStationMatched(station, stationCodeMap.get(s.code), assert)

            // 対応する駅登録があるか
            const registration = registrations.find(r => r.station_code === station.code)
            assert(registration, "対応する駅登録がregister.csvにない")
            if (!registration) throw Error()

            withAssert("register.csv", registration, assert => {
              // 駅登録の順序
              // TODO mainデータセットの場合、check.tsでextraを飛ばしてindexをカウントしている
              assert.equals(idx + 1, registration.index, "駅の登録順が異なる")
              // 駅ナンバリング
              let numbering = s.numbering ? s.numbering.join("/") : null
              assert.equals(numbering, registration.numbering, "駅ナンバリングが異なる")
              // 駅メモ実装での登録駅数をカウント
              // 注意： extraの意味の対象が異なる！
              // line/*.json .station_list[].extra: 駅自体
              // register.csv: 路線に対する駅登録
              if (!hasExtra(registration) || !registration.extra) {
                implSize++
              }
            })
          })

          if (!line.extra) {
            assert(lineStationSize.has(line.name), "路線の登録駅数の確認数が見つからない check/line.csv")
            const expected = lineStationSize.get(line.name) ?? 0
            assert.equals(implSize, expected, "路線の登録駅数（駅メモ実装）が確認駅数 check/line.csv と異なる")
          } else {
            assert.equals(implSize, 0, "路線(extra)の登録駅はすべてextra=trueです")
          }

        })
      }, 10_000)
    })

    describe("polyline/*.json", () => {

      // polyline未定義を許す路線一覧
      const polylineIgnore = readCsvSafe("src/check/polyline_ignore.csv", csvPolylineIgnore).map(e => e.name)

      test("ファイルの有無確認", () => {
        const files = globSync(`${dir}/polyline/*.json`)
        expect(files.length).toBe(lineCodemap.size - polylineIgnore.length)
      })

      test("各ファイルの確認", async () => {
        await assertEachAsync(lineCodemap.values(), "lines", async (line, assert) => {
          if (polylineIgnore.includes(line.name)) {
            return
          }
          const file = `${dir}/polyline/${line.code}.json`
          assert(existsSync(file), "ポリラインファイルが見つからない file:" + file)
          const json = await readJsonSafe(file, jsonPolyline)
          validateGeoPolyline(json)
        })
      })
    })

    describe("KdTree", () => {
      test("tree.json", async () => {
        const file = `${dir}/tree.json`
        const tree = await readJsonSafe(file, jsonKdTree)
        withAssert("tree.json", tree, assert => {
          validateTreeSegment(tree, assert)
          assertObjectSetPartialMatched(tree.node_list, stationCodeMap, ["code", "name", "lat", "lng"])
        })
      })
      describe("segment", () => {
        const files = globSync(`${dir}/tree/*.json`)
        const rootFile = `${dir}/tree/root.json`
        test("ファイルの確認", () => {
          withAssert("tree/*.json", files, assert => {
            const idx = files.indexOf(rootFile)
            assert(idx >= 0, "root.jsonが見つからない")
            files.splice(idx, 1)
            assertEach(files, "files", (file, assert) => {
              const m = file.match(/\/segment[0-9]+[.]json$/)
              assert(m, "segmentファイル名が不正 file:" + file)
            })
          })
        })
        test("各ファイルの確認", async () => {
          const list: Station[] = []
          const segmentMap = new Map<string, number>()
          const schema = jsonKdTreeSegment(dataset)
          await assertEachAsync(files, "files", async (file, assert) => {
            const segment = await readJsonSafe(file, schema)
            assert(!segmentMap.has(segment.name), "segment-name重複している")
            segmentMap.set(segment.name, segment.root)
            assertEach(segment.node_list, "node_list", (node, assert) => {
              assert(!node.segment, "segmentの分割はrootのみ")
              list.push(normalizeStation(node))
            })
            validateTreeSegment(segment, assert)
          })
          await withAssert("root", rootFile, async (assert) => {
            const root = await readJsonSafe(rootFile, schema)
            assert.equals(root.name, "root")
            root.node_list.filter(node => !node.segment).forEach(node => {
              list.push(normalizeStation(node))
            })
            validateTreeSegment(root, assert)
            const segments = root.node_list.filter(node => node.segment)
            assert.equals(segments.length, segmentMap.size, "segmentサイズが一致しない")
            assertEach(segments, "segments", (node, assert) => {
              const name = node.segment ?? ""
              assert(segmentMap.has(name), "segmentが見つからない")
              const code = segmentMap.get(name)
              assert.equals(code, node.code, "segmentのrootが一致しない")
            })
          })
          assertStationSetMatched(list, stationCodeMap)
        })
      })
    })
  })
})