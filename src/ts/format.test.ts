import { readCsvSafe, readJsonSafe } from "./io"
import { csvLine, jsonLineList } from "./model/line"
import { csvStation, jsonStationList } from "./model/station"
import { getAssert } from "./validate/assert"
import { validateLine } from "./validate/line"
import { validateStation } from "./validate/station"

const dataset = process.env.DATASET
if (dataset !== "main" && dataset !== "extra") {
  throw Error(`不明なデータセットの指定：${dataset}`)
}

const extra = dataset === "extra"

describe(`${dataset}データセット`, () => {

  const dir = `out/${extra ? "extra" : "main"}`

  describe("駅データのフォーマット＆整合性確認", () => {
    test("station.csv", () => {
      const file = `${dir}/station.csv`
      readCsvSafe(file, csvStation).forEach((s, i) => {
        const assert = getAssert(`station.csv line:${i}`, s)
        validateStation(s, assert, extra)
      })
    })
    test("station.json", () => {
      const file = `${dir}/station.json`
      readJsonSafe(file, jsonStationList).forEach((s, i) => {
        const assert = getAssert(`station.json root[${i}]`, s)
        validateStation(s, assert, extra)
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