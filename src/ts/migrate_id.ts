import { csvEkimemo } from "../ekimemo/model"
import { readCsvSafe, writeCsvSafe } from "./io"
import { csvLine } from "./model/line"
import { csvStation } from "./model/station"
import { normalizeCSVLine } from "./validate/line"
import { normalizeCSVStation } from "./validate/station"

async function main() {
  // 路線id取得
  const lineIds = new Map(
    readCsvSafe('src/ekimemo/line.csv', csvEkimemo).map(l => [
      l.code,
      l.ekimemo!!,
    ])
  )
  // 路線一覧
  const lines = readCsvSafe('src/line.csv', csvLine('extra')).map(l => normalizeCSVLine(l))
  let extraLineId = 2000
  lines.forEach(l => {
    let id = lineIds.get(l.code)
    if (l.extra) {
      id = extraLineId
      extraLineId++
      console.log('extra line id', id, l.name)
    } else if (!id) {
      throw Error(`id not found for line ${l.code}`)
    }
    l.id = id
  })
  writeCsvSafe('src/line.csv', csvLine('extra'), lines)

  const stationIds = new Map(
    readCsvSafe('src/ekimemo/station.csv', csvEkimemo).map(s => [
      s.code,
      s.ekimemo!!,
    ])
  )
  const stations = readCsvSafe('src/station.csv', csvStation('extra')).map(s => normalizeCSVStation(s))
  let extraStationId = 20000
  stations.forEach(s => {
    let id = stationIds.get(s.code)
    if (s.extra) {
      id = extraStationId
      extraStationId++
      console.log('extra station id', id, s.name)
    } else if (!id) {
      throw Error(`id not found for station ${s.code}`)
    }
    s.id = id
  })
  writeCsvSafe('src/station.csv', csvStation('extra'), stations)
}

main()