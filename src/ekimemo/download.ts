import axios from "axios";
import * as fs from 'fs';
import { JSDOM } from "jsdom";
import { readCsvSafe, writeCsvSafe } from "../ts/io";
import { csvLine } from "../ts/model/line";
import { csvStation } from "../ts/model/station";
import { normalizeCSVLine } from "../ts/validate/line";
import { normalizeCSVStation } from "../ts/validate/station";
import { csvEkimemo, CSVEkimemo } from "./model";
const MAX_LINE_CODE = 700
const MIN_INTERVAL = 300

async function delay(milliseconds: number): Promise<void> {
  if (milliseconds <= 0) return
  return new Promise((resolve, _) => {
    setTimeout(resolve, milliseconds)
  })
}

(async () => {
  // 路線・駅一覧をコピー
  const lines: CSVEkimemo[] = readCsvSafe("src/line.csv", csvLine('extra'))
    .map(l => normalizeCSVLine(l))
    .filter(line => !line.extra)
    .map(line => ({
      code: line.code,
      name: line.name,
      id: null,
    }))
  const stations: CSVEkimemo[] = readCsvSafe("src/station.csv", csvStation('extra'))
    .map(s => normalizeCSVStation(s))
    .filter(line => !line.extra)
    .map(s => ({
      code: s.code,
      name: s.name,
      id: null,
    }))

  // 路線データをダウンロード
  // 1から順に登録されているので、適当に当たりをつけて探索
  for (let code = 1; code <= MAX_LINE_CODE; code++) {
    const start = Date.now()
    let html = ''
    try {
      const res = await axios.get<string>(`https://ekimemo.com/database/line/${code}`)
      if (res.status !== 200) throw Error(`status != 200 at ${code}`)
      html = res.data
    } catch (e) {
      console.warn(`Failed to get page ${e}`)
    }

    if (html.length > 0) {
      const dom = new JSDOM(html)

      // 対応する路線を検索
      const name = dom.window.document.querySelector(".page-title")?.textContent
      if (!name) throw Error(`line name not found at ${code}`)
      const r = lines.find(r => r.name === name)
      if (!r) throw Error("line not found name:" + name)
      r.id = code
      writeCsvSafe("src/ekimemo/line.csv", csvEkimemo, lines)
      fs.writeFileSync(`src/ekimemo/line/${code}.html`, html)

      // 対応する駅を検索
      dom.window.document.querySelectorAll(".line-station-list > .line-station-item").forEach(item => {
        const name = item.querySelector(".station-name")?.textContent
        const path = item.querySelector("a")?.getAttribute("href")
        const code = path?.match(/\/database\/station\/(\d+)\/activity/)?.[1]
        if (!name || !code) throw Error("station name or code not found at line HTML " + code)
        const r = stations.find(r => r.name === name)
        if (!r) throw Error("station not found " + name)
        if (r.id && r.id !== parseInt(code)) throw Error(`station code mismatch ${name} ${code} !== ${r.code}`)
        r.id = parseInt(code)
      })
      writeCsvSafe("src/ekimemo/station.csv", csvEkimemo, stations)

      console.log(code, name)
      dom.window.close()
    }

    const time = Date.now() - start
    await delay(MIN_INTERVAL - time)
  }

  // 路線・駅一覧の欠損を確認
  [...lines, ...stations].forEach(line => {
    if (!line.id) {
      console.error("line/station not found in ekimemo", line)
      throw Error()
    }
  })

  // 駅データをダウンロード
  for (const s of stations) {
    const start = Date.now()

    const res = await axios.get<string>(`https://ekimemo.com/database/station/${s.id}/activity`)
    fs.writeFileSync(`src/ekimemo/station/${s.id}.html`, res.data)
    console.log(s.id, s.name)

    const time = Date.now() - start
    await delay(MIN_INTERVAL - time)
  }
})()