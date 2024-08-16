import axios from "axios";
import { parse } from 'csv-parse/sync';
import * as fs from 'fs';

const MIN_INTERVAL = 300

interface CSVRecord {
  code: string
  name: string
  ekimemo: string
}

const data = fs.readFileSync("src/ekimemo/station.csv")
const stations = parse(data, { columns: true }) as CSVRecord[]

(async () => {
  for (const s of stations) {
    const start = Date.now()
    const res = await axios.get<string>(`https://ekimemo.com/database/station/${s.ekimemo}/activity`)
    fs.writeFileSync(`src/ekimemo/station/${s.ekimemo}.html`, res.data)
    console.log(s.ekimemo, s.name)

    const time = Date.now() - start
    await new Promise((resolve, _) => {
      setTimeout(() => resolve(null), Math.max(MIN_INTERVAL - time, 10))
    })
  }
})()
