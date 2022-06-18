import { readCsvSafe, readJsonSafe } from "./io"
import { csvLine, jsonLineList } from "./model/line"
import { csvStation, jsonStationList } from "./model/station"

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
      readCsvSafe(file, csvStation)
    })
    test("station.json", () => {
      const file = `${dir}/station.json`
      readJsonSafe(file, jsonStationList)
    })
    test("line.csv", () => {
      const file = `${dir}/line.csv`
      readCsvSafe(file, csvLine)
    })
    test("line.json", () => {
      const file = `${dir}/line.json`
      readJsonSafe(file, jsonLineList)
    })
  })
})