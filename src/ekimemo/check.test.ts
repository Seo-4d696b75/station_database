import { readFile } from "fs/promises";
import { readCsvSafe, readJsonSafe } from '../ts/io';
import { jsonLineDetailSrc } from '../ts/model/lineDetail';
import { csvPrefecture } from '../ts/model/prefecture';
import { csvStation } from '../ts/model/station';
import { normalizeCSVStation } from '../ts/validate/station';
import { csvEkimemo } from './model';

describe("駅メモとの差分を検査", () => {
  const lines = readCsvSafe("src/ekimemo/line.csv", csvEkimemo)
  const stations = readCsvSafe("src/ekimemo/station.csv", csvEkimemo)
  const set = new Set(stations.map(s => s.name))

  describe("駅データの確認", () => {
    const data = new Map(
      readCsvSafe("src/station.csv", csvStation('extra'))
        .map(s => normalizeCSVStation(s))
        .filter(s => !s.extra)
        .map(s => [s.id, s])
    )

    const pref_list = readCsvSafe("src/check/prefecture.csv", csvPrefecture)
    const prefectures = new Map(pref_list.map(p => [p.name, p.code]) as [string, number][])

    test('駅数の確認', () => {
      expect(data.size).toBe(stations.length)
    })

    test.concurrent.each(stations)("$name code:$code id:$id", async (station) => {
      const s = data.get(station.id!!)
      expect(s).not.toBeUndefined()
      if (!s) throw Error()

      const html = (await readFile(`src/ekimemo/station/${s.id}.html`)).toString()

      const m = html.match(/<div class="station-name">.*?<div class="pref">(?<pref>.+?)<\/div>.*?<div class="name">(?<name>.+?)<\/div>.*?<div class="kana">(?<kana>.+?)<\/div>/ms)
      if (!m) throw Error("station data not found ")
      const pref = m.groups?.["pref"]!!
      const name = m.groups?.["name"]!!
      const kana = m.groups?.["kana"]!!
      const pref_code = prefectures.get(pref)
      expect(s.prefecture).toBe(pref_code)
      expect(s.name).toBe(name)
      expect(s.name_kana).toBe(kana)

      const path = html.match(/<img\s+src="https:\/\/mfmap.com\/styles\/ekimemo-app\/static\/(?<lng>[\d.]+),(?<lat>[\d.]+),\d+/ms)
      if (!path) throw Error("lat/lng not found " + s.id)
      const lat = parseFloat(path.groups?.["lat"]!!).toFixed(6)
      const lng = parseFloat(path.groups?.["lng"]!!).toFixed(6)
      expect(s.lat.toFixed(6)).toBe(lat)
      expect(s.lng.toFixed(6)).toBe(lng)
    })
  })

  describe("各路線の登録駅を確認", () => {
    test.concurrent.each(lines)("$name code:$code html:$ekimemo", async (line) => {
      // 駅メモ登録駅のみ検査対象
      const detail = await readJsonSafe(`src/line/${line.code}.json`, jsonLineDetailSrc)
      const list_json = detail.station_list.filter(s => set.has(s.name) && !s.extra).map(s => s.name)

      const html = (await readFile(`src/ekimemo/line/${line.id}.html`)).toString()
      const m = html.match(/<ol class="line-station-list">.+?<\/ol>/ms)
      if (!m) throw Error("station list not found ")
      const list = Array.from(m[0].matchAll(/<li class="line-station-item">.+?<div class="station-name">(?<name>.+?)<\/div>.+?<\/li>/msg))
      const list_csv = list.map(item => item?.groups?.["name"]!!)

      // 順序も検査対象
      expect(list_json).toEqual(list_csv)
    })
  })
})