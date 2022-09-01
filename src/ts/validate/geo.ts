import { JSONPolylineGeo, JSONVoronoiGeo } from "../model/geo";
import { Assert, eachAssert, withAssert } from "./assert";

export function validateGeoVoronoi(obj: JSONVoronoiGeo): RectBounds {
  const geometry = obj.geometry
  if (geometry.type === "Polygon") {
    return withAssert("Feature(Polygon)", geometry, assert => {
      const list = geometry.coordinates[0]
      assert(list.length >= 4, "座標リストが短い")
      const start = list[0]
      const end = list[list.length - 1]
      assert.equals(start[0], end[0], "始点と終点の座標が違う[0]")
      assert.equals(start[1], end[1], "始点と終点の座標が違う[1]")
      return validateGeoCoordinates("coordinates[0]", list)
    })
  } else {
    return withAssert("Feature(LineString)", geometry, assert => {
      const list = geometry.coordinates
      assert(list.length >= 2, "座標リストが短い")
      const start = list[0]
      const end = list[list.length - 1]
      assert(`${start[0]}/${start[1]}` !== `${end[0]}/${end[1]}`, "始点と終点の座標が重複している")
      return validateGeoCoordinates("coordinates", list)
    })
  }
}

function validateGeoCoordinates(name: string, list: [number, number][]): RectBounds {
  const rect = initRect()
  let previous = ""
  list.forEach(eachAssert(name, (pos, assert) => {
    const [lng, lat] = pos
    const current = `${lat}/${lng}`
    assert(previous !== current, "直前の座標と重複している")
    previous = current
    addPoint(rect, lat, lng)
  }))
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
    obj.features.forEach(eachAssert("FeatureCollection", (feature, assert) => {
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
    }))
    // rect範囲の確認
    assert.equals(rect.north, obj.properties.north)
    assert.equals(rect.south, obj.properties.south)
    assert.equals(rect.east, obj.properties.east)
    assert.equals(rect.west, obj.properties.west)
    // 幅優先探索でグラフの連結判定
    const queue = [edges[0].start] // 次に探索する頂点のtag
    const history = new Set<string>() // 探索済みの頂点
    let remain = edges // 探索されていない辺
    while (queue.length > 0) {
      const tag = queue.splice(0, 1)[0]
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
    assert(remain.length === 0, "グラフが連結でない")
  })
}