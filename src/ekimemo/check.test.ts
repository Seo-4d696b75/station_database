import { JSONSchemaType } from 'ajv';
import { readFile } from "fs/promises";
import { readCsvSafe, readJsonSafe } from '../ts/io';
import { kanaName, stationLineName } from '../ts/model/common';
import { csvPrefecture } from '../ts/model/prefecture';
import { stationCode, stationLat, stationLng } from '../ts/model/station';

interface CSVEkimemo {
  code: number
  name: string
  /** https://ekimemo.com/database/ で駅・路線を指定するcode */
  ekimemo: number | null
}

const csvEkimemo: JSONSchemaType<CSVEkimemo> = {
  type: "object",
  properties: {
    code: {
      type: "integer",
      minimum: 1000,
      maximum: 9999999,
    },
    name: stationLineName,
    ekimemo: {
      type: "integer",
    },
  },
  required: [
    "code",
    "name",
    "ekimemo",
  ],
  additionalProperties: false,
}

interface JSONLine {
  station_list: {
    name: string
    extra?: boolean
  }[]
}

const jsonLine: JSONSchemaType<JSONLine> = {
  type: "object",
  properties: {
    station_list: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        properties: {
          name: { type: "string" },
          extra: {
            type: "boolean",
            nullable: true,
          }
        },
        required: ["name"]
      },
    }
  },
  required: ["station_list"],
  additionalProperties: true,
}

interface CSVStation {
  code: number,
  name: string
  name_kana: string
  lat: number
  lng: number
  prefecture: number
  extra: boolean
}

const csvStation: JSONSchemaType<CSVStation> = {
  type: "object",
  properties: {
    code: stationCode,
    name: stationLineName,
    name_kana: kanaName,
    lat: stationLat,
    lng: stationLng,
    prefecture: { type: "integer" },
    extra: { type: "boolean" },
  },
  required: [
    "code",
    "name",
    "name_kana",
    "lat",
    "lng",
    "prefecture",
    "extra",
  ],
  additionalProperties: true,
}

describe("駅メモとの差分を検査", () => {
  const lines = readCsvSafe("src/ekimemo/line.csv", csvEkimemo)
  const stations = readCsvSafe("src/ekimemo/station.csv", csvEkimemo)
  const set = new Set(stations.map(s => s.name))

  describe("駅データの確認", () => {
    const ekimemo_codes = new Map(stations.map(r => [r.code, r.ekimemo]))
    const data = readCsvSafe("src/station.csv", csvStation)
      .filter(s => !s.extra)
      .map(s => ({ ...s, ekimemo: ekimemo_codes.get(s.code)!! }))

    const pref_list = readCsvSafe("src/check/prefecture.csv", csvPrefecture)
    const prefectures = new Map(pref_list.map(p => [p.name, p.code]) as [string, number][])

    test.concurrent.each(data)("$name code:$code html:$ekimemo", async (s) => {
      const html = (await readFile(`src/ekimemo/station/${s.ekimemo}.html`)).toString()

      const m = html.match(/<div class="station-name">.*?<div class="pref">(?<pref>.+?)<\/div>.*?<div class="kana">(?<kana>.+?)<\/div>/ms)
      if (!m) throw Error("station data not found ")
      const pref = m.groups?.["pref"]!!
      const kana = m.groups?.["kana"]!!
      const pref_code = prefectures.get(pref)
      expect(s.prefecture).toBe(pref_code)
      expect(s.name_kana).toBe(kana)

      const path = html.match(/<img\s+src="https:\/\/mfmap.com\/styles\/ekimemo-app\/static\/(?<lng>[\d.]+),(?<lat>[\d.]+),\d+/ms)
      if (!path) throw Error("lat/lng not found " + s.ekimemo)
      const lat = parseFloat(path.groups?.["lat"]!!).toFixed(6)
      const lng = parseFloat(path.groups?.["lng"]!!).toFixed(6)
      expect(s.lat.toFixed(6)).toBe(lat)
      expect(s.lng.toFixed(6)).toBe(lng)
    })
  })

  describe("各路線の登録駅を確認", () => {
    test.concurrent.each(lines)("$name code:$code html:$ekimemo", async (line) => {
      // 駅メモ登録駅のみ検査対象
      const detail = readJsonSafe(`src/line/${line.code}.json`, jsonLine)
      const list_json = detail.station_list.filter(s => set.has(s.name) && !s.extra).map(s => s.name)

      const html = (await readFile(`src/ekimemo/line/${line.ekimemo}.html`)).toString()
      const m = html.match(/<ol class="line-station-list">.+?<\/ol>/ms)
      if (!m) throw Error("station list not found ")
      const list = Array.from(m[0].matchAll(/<li class="line-station-item">.+?<div class="station-name">(?<name>.+?)<\/div>.+?<\/li>/msg))
      const list_csv = list.map(item => item?.groups?.["name"]!!)

      expect(list_json).toEqual(list_csv)
    })
  })
})