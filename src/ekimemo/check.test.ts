import { JSONSchemaType } from 'ajv';
import { JSDOM } from "jsdom";
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

  describe("駅", () => {
    const data = readCsvSafe("src/station.csv", csvStation).filter(s => !s.extra)
    const ekimemo_codes = new Map(stations.map(r => [r.code, r.ekimemo]))

    const pref_list = readCsvSafe("src/check/prefecture.csv", csvPrefecture)
    const prefectures = new Map(pref_list.map(p => [p.name, p.code]) as [string, number][])

    test.each(data)("%s", async (s) => {
      const ekimemo = ekimemo_codes.get(s.code)!!

      // https://github.com/jsdom/jsdom/issues/2583#issuecomment-559520814
      const dom = await JSDOM.fromFile(`src/ekimemo/station/${ekimemo}.html`)
      const pref = dom.window.document.querySelector(".station-name > .pref")?.textContent
      const kana = dom.window.document.querySelector(".station-name > .kana")?.textContent
      const path = dom.window.document.querySelector("img.station-map-img")?.getAttribute("src")
      if (!pref || !kana || !path) throw Error("station data not found ")

      const pref_code = prefectures.get(pref)

      expect(s.prefecture).toBe(pref_code)
      expect(s.name_kana).toBe(kana)

      const m = path.match(/\/static\/(?<lng>[\d.]+),(?<lat>[\d.]+),\d+/)
      if (!m) throw Error("lat/lng not found " + ekimemo)
      const lat = parseFloat(m.groups?.["lat"]!!).toFixed(6)
      const lng = parseFloat(m.groups?.["lng"]!!).toFixed(6)
      expect(s.lat.toFixed(6)).toBe(lat)
      expect(s.lng.toFixed(6)).toBe(lng)

      dom.window.close()
    })
  })

  describe("各路線の登録駅を確認", () => {
    test.each(lines)("%s", async (line) => {
      // 駅メモ登録駅のみ検査対象
      const detail = readJsonSafe(`src/line/${line.code}.json`, jsonLine)
      const list_json = detail.station_list.filter(s => set.has(s.name) && !s.extra).map(s => s.name)

      // https://github.com/jsdom/jsdom/issues/2583#issuecomment-559520814
      const dom = await JSDOM.fromFile(`src/ekimemo/line/${line.ekimemo}.html`)
      const list_csv = Array.from(dom.window.document.querySelectorAll(".line-station-list > .line-station-item"))
        .map(item => item.querySelector(".station-name")?.textContent!!)
      dom.window.close()

      expect(list_json).toEqual(list_csv)
    })
  })
})