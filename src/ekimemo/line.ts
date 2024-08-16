import axios from "axios";
import { parse } from 'csv-parse/sync';
import * as fs from 'fs';
import { JSDOM } from "jsdom";

const MAX_LINE_CODE = 700
const MIN_INTERVAL = 500

interface LinePage {
  name: string
  html: string
}

interface LineRecord {
  code: string
  name: string
  ekimemo: string
}

async function getLine(code: number): Promise<LinePage | null> {
  try {
    const res = await axios.get<string>(`https://ekimemo.com/database/line/${code}`)
    if (res.status !== 200) {
      console.log("line not found", code)
      return null
    }
    const dom = new JSDOM(res.data)
    const div = dom.window.document.querySelector(".page-title")
    if (!div) {
      console.warn("line title not found", code)
      return null
    }
    const title = div.textContent!!
    return {
      name: title,
      html: res.data,
    }
  } catch (e) {
    console.warn("Failed to get page", e)
    return null
  }
}

(async () => {
  const data = fs.readFileSync("src/ekimemo/line.csv")
  const lines = parse(data, { columns: true }) as LineRecord[]

  for (let code = 608; code <= MAX_LINE_CODE; code++) {
    const start = Date.now()
    const page = await getLine(code)
    if (page) {
      const r = lines.find(r => r.name === page.name)
      if (!r) throw Error("line not found name:" + page.name)
      r.ekimemo = code.toString()
      fs.writeFileSync(`src/ekimemo/line/${code}.html`, page.html)
      const csv = "code,name,ekimemo\n" + lines.map(r => `${r.code},${r.name},${r.ekimemo}`).join("\n")
      fs.writeFileSync("src/ekimemo/line.csv", csv)
      console.log(code, page.name)
    }
    const time = Date.now() - start
    await new Promise((resolve, _) => {
      setTimeout(() => resolve(null), Math.max(MIN_INTERVAL - time, 10))
    })
  }
})()