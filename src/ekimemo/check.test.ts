import { parse } from 'csv-parse/sync';
import * as fs from 'fs';
import { JSDOM } from "jsdom";

interface CSVRecord {
  code: string
  name: string
  ekimemo: string
}

interface LineDetail {
  name: string
  station_list: {
    code: number
    name: string
    extra: boolean
  }[]
}

describe("各路線の登録駅を確認", () => {
  let data = fs.readFileSync("src/ekimemo/line.csv")
  const lines = parse(data, { columns: true }) as CSVRecord[]
  data = fs.readFileSync("src/ekimemo/station.csv")
  const stations = parse(data, { columns: true }) as CSVRecord[]
  const set = new Set(stations.map(s => s.name))

  for (const line of lines) {
    test(`${line.name}(${line.code})`, async () => {
      const detail = JSON.parse(fs.readFileSync(`src/line/${line.code}.json`).toString()) as LineDetail
      const list_json = detail.station_list.filter(s => set.has(s.name) && !s.extra).map(s => s.name)

      // https://github.com/jsdom/jsdom/issues/2583#issuecomment-559520814
      const dom = await JSDOM.fromFile(`src/ekimemo/line/${line.ekimemo}.html`)
      const list_csv = Array.from(dom.window.document.querySelectorAll(".line-station-list > .line-station-item"))
        .map(item => item.querySelector(".station-name")?.textContent!!)
      dom.window.close()

      expect(list_json).toEqual(list_csv)
    })
  }
})