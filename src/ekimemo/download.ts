import axios from "axios";
import * as fs from 'fs';
import { JSDOM } from "jsdom";
import { writeCsvSafe } from "../ts/io";
import { csvEkimemo, CSVEkimemo } from "./model";
const MAX_LINE_CODE = 700
const MIN_INTERVAL = 300

async function delay(milliseconds: number): Promise<void> {
  if (milliseconds <= 0) return
  return new Promise((resolve, _) => {
    setTimeout(resolve, milliseconds)
  })
}

async function withRetry<T>(
  task: () => Promise<T>,
  shouldRetry: (error: unknown, retryCount: number) => boolean = (_, c) => c < 5,
): Promise<T> {
  let retry = 0
  while (true) {
    try {
      const result = await task()
      return result
    } catch (e) {
      if (!shouldRetry(e, retry)) {
        throw e
      }
      retry++
      await delay(retry * retry * 1000)
    }
  }
}

(async () => {
  const lines: CSVEkimemo[] = []
  const stations: CSVEkimemo[] = []

  // 路線データをダウンロード
  // 1から順に登録されているので、適当に当たりをつけて探索
  for (let lineId = 1; lineId <= MAX_LINE_CODE; lineId++) {
    const start = Date.now()
    let html = ''
    try {
      const res = await withRetry(
        () => axios.get<string>(`https://ekimemo.com/database/line/${lineId}`),
        // 404HTTPステータスはリトライ不要
        (e, c) => c < 5 && (!axios.isAxiosError(e) || e.response?.status !== 404),
      )
      if (res.status !== 200) throw Error(`status != 200 at ${lineId}`)
      html = res.data
    } catch (e) {
      console.warn(`Failed to get page ${e}`)
    }

    if (html.length > 0) {
      const dom = new JSDOM(html)

      // 対応する路線を検索
      const name = dom.window.document.querySelector(".page-title")?.textContent
      if (!name) throw Error(`line name not found at ${lineId}`)

      lines.push({
        name: name,
        id: lineId,
      })

      writeCsvSafe("src/ekimemo/line.csv", csvEkimemo, lines)
      fs.writeFileSync(`src/ekimemo/line/${lineId}.html`, html)

      // 対応する駅を検索
      dom.window.document.querySelectorAll(".line-station-list > .line-station-item").forEach(item => {
        const stationName = item.querySelector(".station-name")?.textContent
        const path = item.querySelector("a")?.getAttribute("href")
        const stationId = path?.match(/\/database\/station\/(\d+)\/activity/)?.[1]
        if (!stationName || !stationId) throw Error("station name or code not found at line HTML " + lineId)
        const station = stations.find(r => r.name === stationName)
        if (station) {
          if (station.id !== parseInt(stationId)) throw Error(`station id mismatch ${stationName} ${stationId} !== ${station.id}`)
        } else {
          stations.push({
            name: stationName,
            id: parseInt(stationId),
          })
        }
      })
      writeCsvSafe("src/ekimemo/station.csv", csvEkimemo, stations)

      console.log(lineId, name)
      dom.window.close()
    }

    const time = Date.now() - start
    await delay(MIN_INTERVAL - time)
  }

  // 駅データをダウンロード
  for (const s of stations) {
    const start = Date.now()

    const res = await withRetry(() => axios.get<string>(`https://ekimemo.com/database/station/${s.id}/activity`))
    fs.writeFileSync(`src/ekimemo/station/${s.id}.html`, res.data)
    console.log(s.id, s.name)

    const time = Date.now() - start
    await delay(MIN_INTERVAL - time)
  }
})()