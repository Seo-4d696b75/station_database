import { parse } from 'csv-parse/sync';
import * as fs from 'fs';
import { JSDOM } from "jsdom";

interface CSVRecord {
  code: string
  name: string
  ekimemo: string
}

let data = fs.readFileSync("src/ekimemo/line.csv")
const lines = parse(data, { columns: true }) as CSVRecord[]
data = fs.readFileSync("src/ekimemo/station.csv")
const stations = parse(data, { columns: true }) as CSVRecord[]

lines.forEach(line => {
  const html = fs.readFileSync(`src/ekimemo/line/${line.ekimemo}.html`)
  const dom = new JSDOM(html)
  const list = dom.window.document.querySelectorAll(".line-station-list > .line-station-item")
  list.forEach(item => {
    const name = item.querySelector(".station-name")?.textContent
    const path = item.querySelector("a")?.getAttribute("href")
    const code = path?.match(/\/database\/station\/(\d+)\/activity/)?.[1]
    if (!name || !code) throw Error("name or code not found at line HTML " + line.ekimemo)
    const r = stations.find(r => r.name === name)
    if (!r) throw Error("station not found " + name)
    if (r.ekimemo !== "NULL" && r.ekimemo !== code) throw Error(`station code mismatch ${name} ${code} !== ${r.code}`)
    r.ekimemo = code
  })
})

const miss = stations.filter(r => r.ekimemo === "NULL")
if (miss.length !== 0) throw Error("station code not found " + miss)

const csv = "code,name,ekimemo\n" + stations.map(r => `${r.code},${r.name},${r.ekimemo}`).join("\n")
fs.writeFileSync("src/ekimemo/station.csv", csv)