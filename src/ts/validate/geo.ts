import { JSONPolylineGeo, JSONVoronoiGeo } from "../model/geo";
import { eachAssert, withAssert } from "./assert";

export function validateGeoFeature(obj: JSONVoronoiGeo): RectBounds {
  const geometry = obj.geometry
  if (geometry.type === "Polygon") {
    return withAssert("Feature(Polygon)", geometry, assert => {
      const list = geometry.coordinates[0]
      assert(list.length >= 3, "座標リストが短い")
      const start = list[0]
      const end = list[list.length - 1]
      assert.equals(start[0], end[0], "始点と終点の座標が違う[0]")
      assert.equals(start[1], end[1], "始点と終点の座標が違う[1]")
      return validateGeoCoordinates("coordinates[0]", list)
    })
  } else {
    return withAssert("Feature(LineString)", geometry, assert => {
      const list = geometry.coordinates
      assert(list.length >= 3, "座標リストが短い")
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
    obj.features.forEach(eachAssert("FeatureCollection", (feature, assert) => {
      const r = validateGeoFeature(feature)
      edges.push(feature.properties)
      rect = unionRect(rect, r)
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
          return true
        }
        let next: string | null = null
        if (edge.start === tag) {
          next = edge.end
        } else if (edge.end === tag) {
          next = edge.start
        }
        if (next && !history.has(next)) {
          history.add(next)
          queue.push(next)
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