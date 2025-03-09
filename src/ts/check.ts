// src/**/* ファイルを入力としてデータ整合性の確認・データの自動補完を行います

import { existsSync } from "fs"
import { fetchAddress } from "./geocoding"
import { readCsvSafe, readJsonSafe, writeCsvSafe, writeJsonSafe } from "./io"
import { CSVLine, csvLine } from "./model/line"
import { jsonLineDetailSrc } from "./model/lineDetail"
import { csvLineStationSize } from "./model/lineStationSize"
import { csvPolylineIgnore } from "./model/polylineIgnore"
import { CSVStation, csvStation } from "./model/station"
import { assertEach, assertEachAsync, withAssert } from "./validate/assert"
import { validatePolylineSrc } from "./validate/geo"
import { normalizeCSVLine, validateLines } from "./validate/line"
import { normalizeCSVStation, Station, validateStations } from "./validate/station"


(async () => {

  const stationMap = new Map<number | string, CSVStation>()
  const lineMap = new Map<number | string, CSVLine>()

  console.log('line.csv 路線一覧の確認')
  const lines = readCsvSafe('src/line.csv', csvLine).map(l => normalizeCSVLine(l))
  validateLines(lines, 'line.csv', true)
  lines.forEach(line => {
    lineMap.set(line.code, line)
    lineMap.set(line.name, line)
  })

  console.log('station.csv 駅一覧の確認')
  const stations = readCsvSafe('src/station.csv', csvStation).map(s => normalizeCSVStation(s))
  validateStations(stations, 'station.csv', true)
  stations.forEach(station => {
    // original_name の検証
    if (station.original_name?.endsWith('駅') ||
      station.original_name?.endsWith('停留所') ||
      station.original_name?.endsWith('乗降場')) {
      console.warn(`駅名の接尾語が不適切な可能性があります:${station.original_name} (${station.code})`)
    }

    stationMap.set(station.code, station)
    stationMap.set(station.name, station)
  })

  console.log('駅の住所・郵便番号を自動補完')
  for (const station of stations) {
    if (station.postal_code === '000-0000' || station.address.match(/^\s*$/)) {
      const address = await fetchAddress(station)
      station.postal_code = address.postal_code
      station.address = address.address
    }
  }
  await writeCsvSafe('src/station.csv', csvStation, stations)
  await writeCsvSafe('src/line.csv', csvLine, lines)

  // 路線の登録駅情報
  console.log('line/*.json 各路線の登録駅を確認')
  const implSizeMap = new Map<string, number>()
  readCsvSafe('src/check/line.csv', csvLineStationSize).forEach(e => {
    implSizeMap.set(e.name, e.size)
  })
  await assertEachAsync(lines, 'line.csv', async (line, assert) => {
    const path = `src/line/${line.code}.json`

    assert(existsSync(path), '路線詳細ファイルが見つかりません')
    const details = readJsonSafe(path, jsonLineDetailSrc)

    await withAssert(path, details, async (assert) => {

      assert.equals(details.name, line.name, '路線詳細の駅名が異なります')

      // 登録駅数の確認
      const size = line.station_size
      assert.equals(details.station_list.length, size, `路線詳細の登録駅数が異なります ${details.name} (${line.code}.json)`)

      // 登録駅の駅コード・駅名の変化があれば更新する
      let write = false
      // 駅メモ登録駅数
      let implSize = 0

      await assertEachAsync(details.station_list, 'station_list', async (station, assert) => {
        const stationCode = station.code
        const stationName = station.name

        // 駅の名前解決
        const maybeStation = stationMap.get(stationName) || stationMap.get(stationCode)
        assert(maybeStation, `路線詳細の登録駅が見つかりません ${stationName}(${stationCode}) at ${details.name} (${line.code}.json)`)

        // assertで存在を確認したので、以降はnon-nullとして扱える
        const validStation = maybeStation as Station

        if (stationCode !== validStation.code) {
          // 駅名の重複なしのため駅名一致なら同値
          console.log(`路線登録駅のコードを自動修正します ${stationName}@${line.name}(${line.code}) ${stationCode}=>${validStation.code}`)
          station.code = validStation.code
          write = true
        } else if (stationName !== validStation.name) {
          // 駅名変更は慎重に
          console.log(`路線登録駅の名称に変更があります ${stationCode}@${line.name}(${line.code}) ${stationName}=>${validStation.name}`)
          const response = await new Promise<string>(resolve => {
            process.stdout.write(' OK? Y/N => ')
            process.stdin.once('data', data => {
              resolve(data.toString().trim())
            })
          })

          assert(response.match(/^[yY]?$/), 'abort')

          station.name = validStation.name
          write = true
        }

        // extra属性の曖昧性を解消
        // src/*.csv extra: 路線・駅自体のextra属性
        // src/line/*.json .station_list[].extra:
        //   路線(extra=true)における駅(extra=true)の登録のうち、
        //   駅メモ実装には含まれない登録のみextra=trueを指定している
        const extra = validStation.extra || line.extra || station.extra
        if (!extra) {
          implSize++
        }

        // 駅要素側にも登録路線を記憶
        if (!validStation.lines.includes(line.code)) {
          validStation.lines.push(line.code)
        }
      })

      // 駅メモ実装の登録駅数を確認
      if (!line.extra) {
        assert(implSizeMap.has(line.name), `路線登録駅の確認数が見つかりません check/line.csv`)
        const expectedSize = implSizeMap.get(line.name)
        assert.equals(implSize, expectedSize, `路線詳細の登録駅数と確認駅数（check/line.csv）が異なります`)
      } else {
        assert.equals(implSize, 0, `路線(extra)の登録駅はすべてextra=trueです`)
      }

      if (write) {
        // 更新あるなら駅登録詳細へ反映
        await writeJsonSafe(path, jsonLineDetailSrc, details, ['.station_list[]'])
      }
    })
  })

  assertEach(stations, 'station.csv', (station, assert) => {

    // 路線の検証
    assert(station.lines.length > 0, '少なくとも１つ以上の路線に登録される必要があります')

    station.lines.forEach(code => {
      assert(lineMap.has(code), `駅の登録路線が見つかりません 路線コード: ${code}`)
    })

    if (!station.closed) {
      const hasActiveLine = station.lines.some(code => {
        const line = lineMap.get(code)
        return line && !line.closed
      })
      assert(hasActiveLine, '現役駅は１つ以上の現役路線に登録される必要があります')
    }
  })

  console.log('polyline/*.json 路線ポリラインの確認')
  const polylineIgnore = readCsvSafe('src/check/polyline_ignore.csv', csvPolylineIgnore).map(line => line.name)

  assertEach(lines, 'station.csv', (line, assert) => {
    const path = `src/polyline/${line.code}.json`
    if (existsSync(path)) {
      validatePolylineSrc(line, path)
    } else {
      assert(
        polylineIgnore.includes(line.name),
        `路線ポリラインが見つかりません.欠損を許可する場合は src/check/polyline.csv への追加が必要です`
      )
    }
  })
})()
