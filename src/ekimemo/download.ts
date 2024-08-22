import axios from "axios";
import * as fs from 'fs';
import { JSDOM } from "jsdom";
import { readCsvSafe } from "../ts/io";
import { csvLine } from "../ts/model/line";
import { csvStation } from "../ts/model/station";

const MAX_LINE_CODE = 700
const MIN_INTERVAL = 300

interface CSVEkimemo {
  code: number
  name: string
  /** https://ekimemo.com/database/ で駅・路線を指定するcode */
  ekimemo: number | null
}

async function delay(milliseconds: number): Promise<void> {
  if (milliseconds <= 0) return
  return new Promise((resolve, _) => {
    setTimeout(resolve, milliseconds)
  })
}

function writeCsv(path: string, lines: CSVEkimemo[]) {
  const csv = "code,name,ekimemo\n" + lines.map(r => `${r.code},${r.name},${r.ekimemo ?? 'NULL'}`).join("\n")
  fs.writeFileSync(path, csv)
}

(async () => {
  // 路線・駅一覧をコピー
  const lines: CSVEkimemo[] = readCsvSafe("src/line.csv", csvLine)
    .filter(line => !line.extra)
    .map(line => ({
      code: line.code,
      name: line.name,
      ekimemo: null,
    }))
  const stations: CSVEkimemo[] = readCsvSafe("src/station.csv", csvStation)
    .filter(line => !line.extra)
    .map(s => ({
      code: s.code,
      name: s.name,
      ekimemo: null,
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
      r.ekimemo = code
      writeCsv("src/ekimemo/line.csv", lines)
      fs.writeFileSync(`src/ekimemo/line/${code}.html`, html)

      // 対応する駅を検索
      dom.window.document.querySelectorAll(".line-station-list > .line-station-item").forEach(item => {
        const name = item.querySelector(".station-name")?.textContent
        const path = item.querySelector("a")?.getAttribute("href")
        const code = path?.match(/\/database\/station\/(\d+)\/activity/)?.[1]
        if (!name || !code) throw Error("station name or code not found at line HTML " + code)
        const r = stations.find(r => r.name === name)
        if (!r) throw Error("station not found " + name)
        if (r.ekimemo && r.ekimemo !== parseInt(code)) throw Error(`station code mismatch ${name} ${code} !== ${r.code}`)
        r.ekimemo = parseInt(code)
      })
      writeCsv("src/ekimemo/station.csv", stations)

      console.log(code, name)
      dom.window.close()
    }

    const time = Date.now() - start
    await delay(MIN_INTERVAL - time)
  }

  // 路線・駅一覧の欠損を確認
  [...lines, ...stations].forEach(line => {
    if (!line.ekimemo) {
      console.error("line/station not found in ekimemo", line)
      throw Error()
    }
  })

  // 駅データをダウンロード
  for (const s of stations) {
    const start = Date.now()

    const res = await axios.get<string>(`https://ekimemo.com/database/station/${s.ekimemo}/activity`)
    fs.writeFileSync(`src/ekimemo/station/${s.ekimemo}.html`, res.data)
    console.log(s.ekimemo, s.name)

    const time = Date.now() - start
    await delay(MIN_INTERVAL - time)
  }
})()