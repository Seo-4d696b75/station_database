import { readJsonSafe } from "../io";
import { JSONPolylineGeo, jsonPolylineSrc, JSONVoronoiGeo } from "../model/geo";
import { CSVLine } from "../model/line";
import { Assert, assertEach, withAssert } from "./assert";

export function validateGeoVoronoi(obj: JSONVoronoiGeo) {
  const geometry = obj.geometry
  if (geometry.type === "Polygon") {
    withAssert("Feature(Polygon)", geometry, assert => {
      const list = geometry.coordinates[0]
      assert(list.length >= 4, "座標リストが短い")
      const start = list[0]
      const end = list[list.length - 1]
      assert.equals(start[0], end[0], "始点と終点の座標が違う[0]")
      assert.equals(start[1], end[1], "始点と終点の座標が違う[1]")
      validateGeoCoordinates("coordinates[0]", list)
    })
  } else {
    withAssert("Feature(LineString)", geometry, assert => {
      const list = geometry.coordinates
      assert(list.length >= 2, "座標リストが短い")
      const start = list[0]
      const end = list[list.length - 1]
      assert(`${start[0]}/${start[1]}` !== `${end[0]}/${end[1]}`, "始点と終点の座標が重複している")
      validateGeoCoordinates("coordinates", list)
    })
  }
}

function validateGeoCoordinates(name: string, list: [number, number][]): RectBounds {
  const rect = initRect()
  let previous = ""
  assertEach(list, name, (pos, assert) => {
    const [lng, lat] = pos
    const current = `${lat}/${lng}`
    assert(previous !== current, "直前の座標と重複している")
    previous = current
    addPoint(rect, lat, lng)
  })
  return rect
}

interface RectBounds {
  north: number
  south: number
  east: number
  west: number
}

const initRect = () => {
  return {
    north: -Number.MAX_VALUE,
    south: Number.MAX_VALUE,
    east: -Number.MAX_VALUE,
    west: Number.MAX_VALUE,
  }
}

function addPoint(rect: RectBounds, lat: number, lng: number) {
  rect.north = Math.max(rect.north, lat)
  rect.south = Math.min(rect.south, lat)
  rect.east = Math.max(rect.east, lng)
  rect.west = Math.min(rect.west, lng)
}

function unionRect(r1: RectBounds, r2: RectBounds): RectBounds {
  return {
    north: Math.max(r1.north, r2.north),
    south: Math.min(r1.south, r2.south),
    east: Math.max(r1.east, r2.east),
    west: Math.min(r1.west, r2.west),
  }
}

interface Edge {
  start: string
  end: string
}

export function validateGeoPolyline(obj: JSONPolylineGeo) {
  withAssert("polyline_list", obj, assert => {
    const edges: Edge[] = []
    let rect = initRect()
    const joinMap = new Map<string, string>()
    const checkJoinCoordinate = (tag: string, pos: [number, number], assert: Assert) => {
      const join = joinMap.get(tag)
      const str = `${pos[0]}/${pos[1]}`
      if (join) {
        assert.equals(str, join, `tag:${tag} の座標が一致しない`)
      } else {
        joinMap.set(tag, str)
      }
    }
    assertEach(obj.features, "FeatureCollection", (feature, assert) => {
      const list = feature.geometry.coordinates
      const start = list[0]
      const end = list[list.length - 1]
      if (feature.properties.start === feature.properties.end) {
        // 環状の場合
        assert(list.length >= 3, "座標リストが短い")
        assert(`${start[0]}/${start[1]}` === `${end[0]}/${end[1]}`, "始点と終点の座標が一致しない")
      } else {
        assert(list.length >= 2, "座標リストが短い")
        assert(`${start[0]}/${start[1]}` !== `${end[0]}/${end[1]}`, "始点と終点の座標が重複している")
      }
      const r = validateGeoCoordinates("coordinates", list)
      edges.push(feature.properties)
      rect = unionRect(rect, r)
      checkJoinCoordinate(feature.properties.start, start, assert)
      checkJoinCoordinate(feature.properties.end, end, assert)
    })
    // rect範囲の確認
    assert.equals(rect.north, obj.properties.north)
    assert.equals(rect.south, obj.properties.south)
    assert.equals(rect.east, obj.properties.east)
    assert.equals(rect.west, obj.properties.west)

    assert(isJointPolyline(edges), "グラフが連結でない")
  })
}

// TODO 独自フォーマット廃止の検討
export function validatePolylineSrc(line: CSVLine, path: string) {
  const data = readJsonSafe(path, jsonPolylineSrc)
  withAssert(path, data, (assert) => {
    assert.equals(data.name, line.name, `路線ポリラインの路線名が異なります`)

    const pointMap = new Map<string, [number, number]>()
    const validatePoint = (tag: string, pos: [number, number], assert: Assert) => {
      if (pointMap.has(tag)) {
        const existingPos = pointMap.get(tag)
        assert(
          pos[0] === existingPos![0] && pos[1] === existingPos![1],
          `路線ポリラインのセグメント末端の座標が一致しません tag:${tag}`
        )
      } else {
        pointMap.set(tag, pos)
      }
    }
    assertEach(data.point_list, 'point_list', (item, assert) => {
      validatePoint(item.start, [item.points[0].lng, item.points[0].lat], assert)
      validatePoint(item.end, [item.points[item.points.length - 1].lng, item.points[item.points.length - 1].lat], assert)

      // 重複確認
      let previous: [number, number] | null = null
      assertEach(item.points, 'points', (p, assert) => {
        const point: [number, number] = [p.lng, p.lat]
        assert(
          !previous || previous[0] !== point[0] || previous[1] !== point[1],
          `路線ポリラインの座標が重複しています ${JSON.stringify(point)}@${line.name}(${line.code})`
        )
        previous = point
      })
    })

    // ポリラインの各セグメントが正しく連結されているか（互いに到達可能か）確認する
    assert(isJointPolyline(data.point_list), `路線ポリラインの各セグメントが連結ではありません. `)
  })
}

// 幅優先探索でグラフの連結判定
function isJointPolyline(edges: Edge[]): boolean {
  const queue: string[] = [] // 次に探索する頂点のtag
  const history = new Set<string>() // 探索済みの頂点
  queue.push(edges[0].start)
  history.add(edges[0].start)
  let remain = [...edges] // 探索されていない辺
  while (queue.length > 0) {
    const tag = queue.shift()!
    // 隣接点を探してまだ探索していない場合は、
    // 辺を削除＆隣接点を次の探索点として追加
    remain = remain.filter(edge => {
      if (edge.start === edge.end) {
        // 例外
        // 環状線など一部の路線では辺でループを表現している
        return false
      }
      let next: string | null = null
      if (edge.start === tag) {
        next = edge.end
      } else if (edge.end === tag) {
        next = edge.start
      }
      if (next) {
        if (!history.has(next)) {
          history.add(next)
          queue.push(next)
        }
        return false
      }
      return true
    })
  }
  // queueが空になったら探索終了
  // すべての辺が探索済みなら連結グラフ
  return remain.length === 0
}
