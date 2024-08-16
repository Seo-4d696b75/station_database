import { parse } from 'csv-parse/sync';
import * as fs from 'fs';
import { JSDOM } from "jsdom";

interface CSVRecord {
  code: string
  name: string
  ekimemo: string
}

interface StationRecord {
  code: string
  name: string
  name_kana: string
  lat: string
  lng: string
  prefecture: string
  extra: string
}

(async () => {

  let data = fs.readFileSync("src/ekimemo/station.csv")
  const records = parse(data, { columns: true }) as CSVRecord[]
  const ekimemo_codes = new Map(records.map(r => [r.code, r.ekimemo]))
  data = fs.readFileSync("src/station.csv")
  const stations = parse(data, { columns: true }) as StationRecord[]
  data = fs.readFileSync("src/prefecture.csv")
  const pref_list = parse(data) as string[][]
  const prefectures = new Map(pref_list.map(p => [p[1], parseInt(p[0])]) as [string, number][])

  for (const s of stations) {
    if (s.extra === "1") continue

    const ekimemo = ekimemo_codes.get(s.code)!!
    // https://github.com/jsdom/jsdom/issues/2583#issuecomment-559520814
    const dom = await JSDOM.fromFile(`src/ekimemo/station/${ekimemo}.html`)
    const pref = dom.window.document.querySelector(".station-name > .pref")?.textContent
    const kana = dom.window.document.querySelector(".station-name > .kana")?.textContent
    const path = dom.window.document.querySelector("img.station-map-img")?.getAttribute("src")
    if (!pref || !kana || !path) throw Error("station data not found " + ekimemo)

    const pref_code = prefectures.get(pref)
    if (!pref_code) throw Error("prefecture not found " + pref)
    if (pref_code !== parseInt(s.prefecture)) {
      console.error("prefecture mismatch", pref, s)
      throw Error()
    }

    if (kana !== s.name_kana) {
      console.error("kana mismatch", kana, s)
      throw Error()
    }


    const m = path.match(/\/static\/(?<lng>[\d.]+),(?<lat>[\d.]+),\d+/)
    if (!m) throw Error("lat/lng not found " + ekimemo)
    const lat = parseFloat(m.groups?.["lat"]!!).toFixed(6)
    const lng = parseFloat(m.groups?.["lng"]!!).toFixed(6)
    if (lat !== s.lat || lng !== s.lng) {
      console.log(`coordinates updated ${s.name} ${s.lat}/${s.lng} => ${lat}/${lng}`)
      s.lat = lat
      s.lng = lng
    }

    dom.window.close()
  }

  const csv = [
    Object.entries(stations[0]).map(e => e[0]).join(","),
    ...stations.map(s => Object.entries(s).map(e => e[1] as string).join(",")),
  ].join("\n")
  fs.writeFileSync("src/station.csv", csv)
})()