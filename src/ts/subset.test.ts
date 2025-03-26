import { readJsonSafe } from './io'
import { jsonLineList } from './model/line'
import { jsonLineDetail } from './model/lineDetail'
import { jsonStationList } from './model/station'
import { assertEach } from './validate/assert'
import { Line, normalizeJSONLine } from './validate/line'
import { normalizeJSONStation, Station } from './validate/station'

describe('mainデータセットがextraデータセットのサブセットであることを確認', () => {

  function assertObjectEquals<T>(main: T, extra: T, keys: (keyof T)[]) {
    assertEach(keys, 'keys', (key, assert) => {
      const mainValue = main[key]
      const extraValue = extra[key]
      if ((key === 'lines' || key === 'station_list') && Array.isArray(mainValue) && Array.isArray(extraValue)) {
        const normalizedMain = mainValue.map(m => typeof m === 'object' ? JSON.stringify(m) : m)
        const normalizedExtra = extraValue.map(e => typeof e === 'object' ? JSON.stringify(e) : e)
        assert(normalizedMain.every(m => normalizedExtra.includes(m)), 'Arrayの値が一致しません')
      } else if (key === 'station_size' && typeof mainValue === 'number' && typeof extraValue === 'number') {
        assert(mainValue <= extraValue, '路線登録駅数は main <= extra')
      } else {
        assert(mainValue === extraValue, '値が一致しません')
      }
    })
  }

  test('駅データの整合性確認', async () => {
    const mainStations = (await readJsonSafe('out/main/station.json', jsonStationList('main'))).map(s => normalizeJSONStation(s))
    const extraStations = (await readJsonSafe('out/extra/station.json', jsonStationList('extra'))).map(s => normalizeJSONStation(s))
    const extraStationsMap = new Map(extraStations.map(s => [s.code, s]))
    const keys: (keyof Station)[] = [
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
      // 'voronoi' 近傍の駅が変化すると影響を受けるため対象外
    ]
    assertEach(mainStations, 'station.json', (station, assert) => {
      assert(!station.extra)
      const extraStation = extraStationsMap.get(station.code)
      assert(extraStation, 'extraデータセットに対応する駅が見つかりません')
      if (!extraStation) throw new Error()
      assert(!extraStation.extra, 'データセット間でextraが一致しない')
      assertObjectEquals(station, extraStation, keys)
      extraStationsMap.delete(station.code)
    })

    // 残りのextra駅の確認
    assertEach(extraStationsMap, 'station.json', ([code, station], assert) => {
      assert(station.extra, 'extraデータセット固有の駅はextra=true')
    })
  })

  test('路線データの整合性確認', async () => {

    interface LineDetail extends Line {
      // 登録駅の識別子とナンバリングのみ分かれば十分
      station_list: {
        code: number
        name: string
        numbering?: string[]
      }[]
    }

    const mainDetailSchema = jsonLineDetail('main')
    const mainLines: LineDetail[] = await Promise.all((await readJsonSafe('out/main/line.json', jsonLineList('main'))).map(async (l) => {
      let detail = await readJsonSafe(`out/main/line/${l.code}.json`, mainDetailSchema)
      return {
        ...normalizeJSONLine(l),
        // JSON.stringify で等価判定するため余計なプロパティを除去しておく
        station_list: detail.station_list.map(s => ({
          code: s.code,
          name: s.name,
          numbering: s.numbering
        }))
      }
    }))

    const extraDetailSchema = jsonLineDetail('extra')
    const extraLines: LineDetail[] = await Promise.all((await readJsonSafe('out/extra/line.json', jsonLineList('extra'))).map(async (l) => {
      let detail = await readJsonSafe(`out/extra/line/${l.code}.json`, extraDetailSchema)
      return {
        ...normalizeJSONLine(l),
        station_list: detail.station_list.map(s => ({
          code: s.code,
          name: s.name,
          numbering: s.numbering
        }))
      }
    }))
    const extraLinesMap = new Map(extraLines.map(l => [l.code, l]))
    const keys: (keyof LineDetail)[] = [
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
    ]
    assertEach(mainLines, 'line.json', (line, assert) => {
      assert(!line.extra)
      const extraLine = extraLinesMap.get(line.code)
      assert(extraLine, 'extraデータセットに対応する路線が見つかりません')
      if (!extraLine) throw new Error()
      assert(!extraLine.extra, 'データセット間でextraが一致しない')
      assertObjectEquals(line, extraLine, keys)
      extraLinesMap.delete(line.code)
    })

    // 残りのextra路線の確認
    assertEach(extraLinesMap, 'line.json', ([code, line], assert) => {
      assert(line.extra, 'extraデータセット固有の路線はextra=true')
    })
  })
})