import { existsSync, unlinkSync } from 'fs'
import { glob } from 'glob'
import yargs from 'yargs'
import { hideBin } from 'yargs/helpers'
import { readCsvSafe, readJsonSafe, writeCsvSafe, writeJsonSafe } from './io'
import { JSONDiagramStation, jsonDiagramStations, KdTreeParser } from './kdtree'
import { Dataset } from './model/dataset'
import { jsonDelaunayList } from './model/delaunay'
import { convertToPolylineGeo, jsonPolyline, jsonPolylineSrc } from './model/geo'
import { csvLine, JSONLine, jsonLineList } from './model/line'
import { jsonLineDetail, JSONLineDetail, jsonLineDetailSrc, JSONStationRegistration } from './model/lineDetail'
import { csvRegister, CSVStationRegister } from './model/register'
import { csvStation, JSONStation, jsonStationList } from './model/station'
import { jsonKdTree, jsonKdTreeSegment, JSONKdTreeSegment, JSONStationNode } from './model/tree'
import { assertEach, withAssert } from './validate/assert'
import { normalizeCSVLine } from './validate/line'
import { normalizeCSVStation } from './validate/station'

// CLI引数の解析
const argv = yargs(hideBin(process.argv))
  .option('extra', {
    alias: 'e',
    type: 'boolean',
    description: 'extraデータセットを対象とします',
    default: false
  })
  .help()
  .argv


type MergedStation = JSONStation<'extra'> & JSONDiagramStation
type MergedLine = JSONLine<'extra'> & JSONLineDetail<'extra'>

async function main() {
  const dataset: Dataset = (await Promise.resolve(argv)).extra ? 'extra' : 'main'
  const dir = `out/${dataset}`

  // clean
  console.log('cleaning')
  const files = await glob(`${dir}/**/*.{json,csv}`)
  files.forEach(file => {
    if (existsSync(file)) {
      unlinkSync(file)
    }
  })

  // 駅・路線マスターデータの取得
  console.log('reading src/*.csv')
  let stations = readCsvSafe('src/station.csv', csvStation('extra')).map(s => normalizeCSVStation(s))
  let lines = readCsvSafe('src/line.csv', csvLine('extra')).map(l => normalizeCSVLine(l))

  const stationMap = new Map(stations.map(s => [s.code, s]))

  // データセットの調整
  if (dataset === 'main') {
    stations = stations.filter(s => !s.extra)
    lines = lines.filter(l => !l.extra)
  }

  // 駅の詳細（ボロノイ領域・隣接点・Kd-tree）
  console.log('read src/diagram/build/*.json')
  const treePath = `src/diagram/build/diagram${dataset === 'extra' ? '.extra' : ''}.json`
  const tree = readJsonSafe(treePath, jsonDiagramStations)

  // 駅の全ての情報をまとめる
  const mergedStations = new Map<number, MergedStation>()

  withAssert(treePath, tree, assert => {
    assert.equals(tree.node_list.length, stations.length, 'kd-tree頂点数が駅数と異なります')

    assertEach(tree.node_list, "node_list", (e, assert) => {
      // 対応する駅
      const s = stationMap.get(e.code)
      assert(s, `kd-treeの頂点に対応する駅が見つかりません`)
      const merged: MergedStation = {
        ...s!,
        ...e,
        lines: [],
        attr: s!.attr ?? undefined,
        open_date: s!.open_date ?? undefined,
        closed_date: s!.closed_date ?? undefined,
      }
      mergedStations.set(e.code, merged)
    })

  })

  // 路線登録駅の取得
  console.log('reading src/line/*.json')
  const registers: CSVStationRegister<'extra'>[] = []
  const mergedLines: MergedLine[] = []

  assertEach(lines, "lines", (line, assert) => {
    const path = `src/line/${line.code}.json`
    const details = readJsonSafe(path, jsonLineDetailSrc)
    const merged: MergedLine = withAssert(path, details, assert => {
      let count = 0
      const list: (JSONStationRegistration & JSONStation<'extra'>)[] = assertEach(
        details.station_list,
        ".station_list",
        (r, assert) => {
          // 注意：mainデータセットでr.codeの駅がextraの場合はundefinedになる
          const station = mergedStations.get(r.code)
          assert(dataset === 'main' || station, `codeに対応する駅が見つかりません`)

          // extra属性の曖昧性を解消
          // src/*.csv extra: 路線・駅自体のextra属性
          // src/line/*.json .station_list[].extra:
          //   路線(extra=true)における駅(extra=true)の登録のうち、
          //   駅メモ実装には含まれない登録のみextra=trueを指定している
          const isExtraRegister = !!(
            (station === undefined || station.extra) ||
            line.extra ||
            r.extra
          )

          // mainデータセットの登録駅に注意
          if (dataset === 'main' && isExtraRegister) return null

          if (!station) throw new Error('not reachable')

          count++
          registers.push({
            station_code: station.code,
            line_code: line.code,
            index: count,
            numbering: r.numbering ? r.numbering.join('/') : null,
            extra: isExtraRegister,
          })

          // 駅要素側にも登録路線を記憶
          station.lines.push(line.code)

          // 駅の詳細情報を追加する
          // extraの意味が路線登録=>駅自体に変わる点に注意
          let { extra, ...rest } = r
          return { ...station, ...rest }
        },
      ).filter((s): s is NonNullable<typeof s> => s !== null)
      return {
        ...line,
        station_list: list,
        station_size: list.length,
        name_formal: line.name_formal ?? undefined,
        company_code: line.company_code ?? undefined,
        color: line.color ?? undefined,
        symbol: line.symbol ?? undefined,
        closed: line.closed ?? false,
        closed_date: line.closed_date ?? undefined,
      }
    })
    mergedLines.push(merged)

    // データセットに合わせた登録駅数に調整
    if (dataset === 'main') {
      line.station_size = merged.station_size
    }
  })

  // line/*.json
  console.log(`writing ${dir}/line/*.json`)
  await Promise.all(mergedLines.map(async line => {
    await writeJsonSafe(
      `${dir}/line/${line.code}.json`,
      jsonLineDetail(dataset),
      line,
      ['.station_list[]'],
    )
  }))

  // *.json
  console.log(`writing ${dir}/*.json`)
  await writeJsonSafe(
    `${dir}/line.json`,
    jsonLineList(dataset),
    mergedLines,
    ['.[]'],
  )
  await writeJsonSafe(
    `${dir}/station.json`,
    jsonStationList(dataset),
    Array.from(mergedStations.values()),
    ['.[]'],
  )
  await writeJsonSafe(
    `${dir}/tree.json`,
    jsonKdTree,
    tree,
    ['.node_list[]'],
  )
  await writeJsonSafe(
    `${dir}/delaunay.json`,
    jsonDelaunayList,
    Array.from(mergedStations.values()),
    ['.[]']
  )

  // *.csv
  console.log(`writing ${dir}/*.csv`)
  await writeCsvSafe(`${dir}/station.csv`, csvStation(dataset), stations)
  await writeCsvSafe(`${dir}/line.csv`, csvLine(dataset), lines)
  await writeCsvSafe(`${dir}/register.csv`, csvRegister(dataset), registers)

  // polyline/*.json
  console.log(`writing ${dir}/polyline/*.json`)
  await Promise.all(lines.map(async line => {
    const src = `src/polyline/${line.code}.json`
    if (!existsSync(src)) return

    const data = readJsonSafe(src, jsonPolylineSrc)
    const geoData = convertToPolylineGeo(data, dataset)

    await writeJsonSafe(
      `${dir}/polyline/${line.code}.json`,
      jsonPolyline,
      geoData,
      ['.features[].geometry.coordinates']
    )
  }))

  // tree/*.json
  console.log(`writing ${dir}/tree/*.json`)
  const root = new KdTreeParser(mergedStations.get(tree.root)!, 0, mergedStations)
  const segments = root.serialize(4)

  await Promise.all(segments.map(async seg => {
    const merged: JSONKdTreeSegment<JSONStationNode<'extra'>> = {
      ...seg,
      node_list: seg.node_list.map(n => {
        const s = mergedStations.get(n.code)
        return { ...s!, ...n }
      })
    }

    await writeJsonSafe(
      `${dir}/tree/${seg.name}.json`,
      jsonKdTreeSegment(dataset),
      merged,
      ['.node_list[]']
    )
  }))
}

main().catch(error => {
  console.error('エラーが発生しました:', error)
  process.exit(1)
})
