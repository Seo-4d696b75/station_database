import { existsSync, writeFileSync } from 'fs'
import { join } from 'path'
import { readJsonSafe } from './io'
import { parseDataset } from './model/dataset'
import { jsonPolyline, JSONPolylineGeo } from './model/geo'
import { jsonLineList } from './model/line'
import { jsonLineDetail } from './model/lineDetail'
import { jsonStationList } from './model/station'
import { assertEach } from './validate/assert'
import { Line, normalizeJSONLine } from './validate/line'
import { normalizeJSONStation, Station } from './validate/station'


const dataset = parseDataset(process.env.DATASET)
const extra = dataset === "extra"

interface LogTag {
  name: string
  type: 'station' | 'line'
}

interface DiffLog extends LogTag {
  messages: string[]
}

function pushLog(logs: DiffLog[], tag: LogTag, message: string) {
  const log = logs.find(l => l.name === tag.name && l.type === tag.type)
  if (log) {
    log.messages.push(message)
  } else {
    logs.push({ ...tag, messages: [message] })
  }
}

function normalizeValue(key: string, value: any): any {
  if (!value || typeof value !== 'object') {
    return value
  } else if (key === 'lines' && Array.isArray(value)) {
    return [...value].sort().join(',')
  } else if (key === 'station_list' && Array.isArray(value)) {
    // 駅名・駅コード等は変化するためidで確認する
    return value.map(e => ({
      id: e.id,
      number: e.number,
    })).join(',')
  } else if (key === 'polyline' && value) {
    return JSON.stringify(value)
  }
  throw new Error(`unexpected type ${typeof value} key: ${key}`)
}

function formatMd(value: any, key: string): string {
  if (key === 'polyline') {
    return '`{..data..}`'
  }

  if (key === 'station_list' && Array.isArray(value)) {
    let list = value.map((e: any) => {
      const name = e.name
      const n = e.numbering
      return Array.isArray(n) ? `${name}(${n.join(',')})` : name
    })
    return `\`${JSON.stringify(list)}\``
  }

  if (Array.isArray(value) || typeof value === 'object') {
    return `\`${JSON.stringify(value)}\``
  }

  if (typeof value === 'number' || typeof value === 'string' || typeof value === 'boolean') {
    return String(value)
  }

  if (value === null) {
    return 'null'
  }

  throw new Error(`unexpected type ${value} ${typeof value}`)
}

describe('データ更新の差分を検出', () => {
  const oldDir = extra ? 'artifact/extra' : 'artifact/main'
  const newDir = extra ? 'out/extra' : 'out/main'
  const logFile = extra ? 'diff.extra.md' : 'diff.md'
  const logTitle = extra ? 'extraデータセットの差分' : 'mainデータセットの差分'

  const logs: DiffLog[] = []

  // object の第１階層のみ検査する
  function checkDiff<T>(tag: LogTag, old: T, current: T, fields: (keyof T & string)[]) {
    fields.forEach(key => {
      const oldValue = normalizeValue(key, old[key])
      const newValue = normalizeValue(key, current[key])
      if (oldValue === newValue) return

      const oldFormatted = formatMd(old[key], key)
      const newFormatted = formatMd(current[key], key)

      pushLog(logs, tag, `${key}: ${oldFormatted}=>${newFormatted}`)
    })
  }

  test('駅データの更新差分を確認', async () => {
    // 新しいデータセットを読み込み
    const newStations = (await readJsonSafe(join(newDir, 'station.json'), jsonStationList(dataset))).map(s => normalizeJSONStation(s))

    // 古いデータセットを読み込み
    const oldStations = (await readJsonSafe(join(oldDir, 'station.json'), jsonStationList(dataset))).map(s => normalizeJSONStation(s))

    // 新しいデータセットのマップを作成
    const stations = new Map(newStations.map(s => [s.id, s]))

    const stationFields: (keyof Station & string)[] = [
      'code',
      'id',
      'name',
      'original_name',
      'name_kana',
      'closed',
      'lat',
      'lng',
      'prefecture',
      'lines',
      'attr',
      'postal_code',
      'address',
      'open_date',
      'closed_date',
      'extra',
      // 'voronoi' 近傍の駅座標が変化すると影響を受けるため対象外
    ]

    // 古い駅データとの差分を確認
    assertEach(oldStations, 'station.json', (old, assert) => {
      const station = stations.get(old.id)
      assert(station || old.extra, `新バージョンのデータセットに対応する駅が見つかりません`)

      if (!station && !old.extra) throw new Error()

      if (station) {
        const tag = {
          name: `変更: ${station.name}(${station.code})`,
          type: 'station' as const
        }
        checkDiff(tag, old, station, stationFields)
      } else {
        // extra駅のみ削除を許可する
        const tag = {
          name: `削除: ${old.name}(${old.code})`,
          type: 'station' as const
        }
        pushLog(logs, tag, '')
      }
      stations.delete(old.id)
    })

    // 新規追加の駅を記録
    stations.forEach(station => {
      const tag = {
        name: `追加: ${station.name}(${station.code})`,
        type: 'station' as const
      }
      pushLog(logs, tag, '')
    })
  })

  test('路線データの更新差分を確認', async () => {

    interface LineDetail extends Line {
      // 登録駅の識別子とナンバリングのみ分かれば十分
      station_list: {
        id: number
        code: number
        name: string
        numbering?: string[]
      }[]
      polyline?: JSONPolylineGeo
    }

    // 古いデータセットを読み込み
    let schema = jsonLineDetail(dataset)
    const oldLines: LineDetail[] = await Promise.all((await readJsonSafe(join(oldDir, 'line.json'), jsonLineList(dataset))).map(async (l) => {
      let detail = await readJsonSafe(join(oldDir, `line/${l.code}.json`), schema)
      let path = join(oldDir, `polyline/${l.code}.json`)
      if (existsSync(path)) {
        let polyline = await readJsonSafe(path, jsonPolyline)
        return {
          ...normalizeJSONLine(l),
          polyline,
          station_list: detail.station_list,
        }
      } else {
        return {
          ...normalizeJSONLine(l),
          station_list: detail.station_list,
        }
      }
    }))

    // 新しいデータセットのマップを作成
    const newLines: LineDetail[] = await Promise.all((await readJsonSafe(join(newDir, 'line.json'), jsonLineList(dataset))).map(async (l) => {
      let detail = await readJsonSafe(join(newDir, `line/${l.code}.json`), schema)
      let path = join(newDir, `polyline/${l.code}.json`)
      if (existsSync(path)) {
        let polyline = await readJsonSafe(path, jsonPolyline)
        return {
          ...normalizeJSONLine(l),
          polyline,
          station_list: detail.station_list,
        }
      } else {
        return {
          ...normalizeJSONLine(l),
          station_list: detail.station_list,
        }
      }
    }))

    const lines = new Map(newLines.map(l => [l.id, l]))

    const lineFields: (keyof LineDetail)[] = [
      'code',
      'id',
      'name',
      'name_kana',
      'name_formal',
      'station_size',
      'company_code',
      'closed',
      'color',
      'symbol',
      'closed_date',
      'extra',
      'station_list',
      'polyline',
    ]

    // 古い路線データとの差分を確認
    assertEach(oldLines, 'line.json', (old, assert) => {
      const line = lines.get(old.id)
      assert(line, `新バージョンのデータセットに対応する路線が見つかりません`)
      if (!line) throw new Error()

      const tag = {
        name: `変更: ${line.name}(${line.code})`,
        type: 'line' as const
      }
      checkDiff(tag, old, line, lineFields)
      lines.delete(old.id)
    })

    // 新規追加の路線を記録
    lines.forEach(line => {
      const tag = {
        name: `追加: ${line.name}(${line.code})`,
        type: 'line' as const
      }
      pushLog(logs, tag, '')
    })
  })

  afterAll(() => {
    // 差分ログを生成
    let logContent = `## ${logTitle}  \n\n`

    if (logs.length === 0) {
      logContent += "差分はありません\n"
    } else {
      logContent += `<details><summary>${logs.length}件の差分があります</summary>\n\n`

      // 路線の差分
      const lineLogs = logs.filter(l => l.type === 'line')
      if (lineLogs.length > 0) {
        logContent += "### 路線\n\n"
        lineLogs.forEach(l => {
          logContent += `- ${l.name}  \n`
          let messages = l.messages.filter(m => m.length > 0)
          if (messages.length > 0) {
            messages.forEach(m => {
              logContent += `  - ${m}  \n`
            })
          }
        })
      }

      logContent += "\n"

      // 駅の差分
      const stationLogs = logs.filter(l => l.type === 'station')
      if (stationLogs.length > 0) {
        logContent += "### 駅\n\n"
        stationLogs.forEach(l => {
          logContent += `- ${l.name}  \n`
          let messages = l.messages.filter(m => m.length > 0)
          if (messages.length > 0) {
            messages.forEach(m => {
              logContent += `  - ${m}  \n`
            })
          }
        })
      }
    }

    logContent += "\n</details>\n\n"

    // 差分ログを保存
    writeFileSync(join('artifact', logFile), logContent)
  })
}) 