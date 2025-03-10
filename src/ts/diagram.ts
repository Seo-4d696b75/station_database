import { JSONSchemaType } from 'ajv'
import { readCsvSafe, writeJsonSafe } from './io'
import { csvStation } from './model/station'

// 駅座標図形計算の入力データを用意する
//
// - 入力: src/station.csv
// - 出力:
//   - src/diagram/build/station.json
//   - src/diagram/build/station.extra.json

interface DiagramStation {
  code: number
  name: string
  lat: number
  lng: number
}

const jsonDiagramStations: JSONSchemaType<DiagramStation[]> = {
  type: 'array',
  items: {
    type: 'object',
    properties: {
      code: { type: 'number' },
      name: { type: 'string' },
      lat: { type: 'number' },
      lng: { type: 'number' },
    },
    required: ['code', 'name', 'lat', 'lng'],
    additionalProperties: false,
  },
}

async function main() {
  const stations = readCsvSafe('src/station.csv', csvStation)

  // extraデータセット
  console.log(`extraデータセット：${stations.length}`)
  await writeJsonSafe<DiagramStation[]>(
    'src/diagram/build/station.extra.json',
    jsonDiagramStations,
    stations,
    ['.[]']
  )

  // mainデータセット
  const main = stations.filter(s => !s.extra)
  console.log(`mainデータセット：${main.length}`)
  await writeJsonSafe(
    'src/diagram/build/station.json',
    jsonDiagramStations,
    main,
    ['.[]']
  )
}

// エラーハンドリングを追加して実行
main().catch(error => {
  console.error('エラーが発生しました:', error)
  process.exit(1)
})
