import { JSONSchemaType } from "ajv"
import { stationLineName } from "./common"

const lat: JSONSchemaType<number> = {
  type: "number",
  minimum: 20,
  maximum: 60,
  title: "緯度"
}

const lng: JSONSchemaType<number> = {
  type: "number",
  minimum: 112,
  maximum: 160,
  title: "経度"
}


const coordinate: JSONSchemaType<[number, number]> = {
  type: "array",
  minItems: 2,
  maxItems: 2,
  items: [
    // lng,latの順序
    lng,
    lat,
  ],
  title: "座標点",
  description: "緯度・経度の組み合わせで座標を表します. リストの長さは２で固定で、経度・緯度の順番です.",
  examples: [
    [140.731677, 41.776316],
  ],
}

export interface JSONVoronoiGeo {
  type: "Feature"
  geometry: {
    type: "Polygon"
    coordinates: [[number, number][]]
  } | {
    type: "LineString"
    coordinates: [number, number][]
  }
  properties: {}
}

export const jsonVoronoi: JSONSchemaType<JSONVoronoiGeo> = {
  type: "object",
  title: "ボロノイ範囲",
  description: "原則としてポリゴンで表現されます. ただし外周部の一部駅のボロノイ範囲は閉じていないため、ポリライン(LineString)で表現されます. JSONによる図形の表現方法は[GeoJSON](https://geojson.org/geojson-spec.html)に従います.",
  examples: [
    { "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [[[140.72591, 41.771256], [140.717527, 41.773829], [140.71735, 41.774204], [140.714999, 41.785757], [140.714787, 41.792259], [140.72972, 41.788694], [140.730562, 41.78452], [140.731074, 41.778908], [140.72591, 41.771256]]] }, "properties": {} }
  ],
  properties: {
    type: {
      type: "string",
      const: "Feature"
    },
    geometry: {
      type: "object",
      title: "geometry(Polygon/LineString)",
      required: [
        "type",
        "coordinates",
      ],
      oneOf: [
        {
          type: "object",
          title: "geometry(Polygon)",
          examples: [
            { "type": "Polygon", "coordinates": [[[140.72591, 41.771256], [140.717527, 41.773829], [140.71735, 41.774204], [140.714999, 41.785757], [140.714787, 41.792259], [140.72972, 41.788694], [140.730562, 41.78452], [140.731074, 41.778908], [140.72591, 41.771256]]] }
          ],
          properties: {
            type: {
              type: "string",
              const: "Polygon"
            },
            coordinates: {
              type: "array",
              title: "Polygonの座標リスト",
              description: "ボロノイ範囲は中空のないポリゴンのため、長さ１のリスト",
              examples: [
                [[[140.72591, 41.771256], [140.717527, 41.773829], [140.71735, 41.774204], [140.714999, 41.785757], [140.714787, 41.792259], [140.72972, 41.788694], [140.730562, 41.78452], [140.731074, 41.778908], [140.72591, 41.771256]]]
              ],
              // ボロノイ領域は中空のないポリゴン
              minItems: 1,
              maxItems: 1,
              items: {
                type: "array",
                minItems: 3,
                items: coordinate,
                title: "Polygonの座標リスト[0]",
                description: "始点と終点の座標が一致します",
              }
            },
          },
          required: [
            "type",
            "coordinates",
          ],
          additionalProperties: false,
        },
        {
          type: "object",
          title: "geometry(LineString)",
          examples: [
            { "type": "LineString", "coordinates": [[160.0, 32.2175], [145.486252, 43.24743], [145.480118, 43.249398], [145.412432, 42.926476], [145.393203, 42.31716], [145.394284, 42.306034], [145.479425, 41.700239], [146.005674, 39.188776], [149.514356, 35.886453], [150.83862, 34.697293], [151.547974, 34.255494], [160.0, 29.000091]] }
          ],
          properties: {
            // 外周部の一部は閉じていない
            type: {
              type: "string",
              const: "LineString"
            },
            coordinates: {
              type: "array",
              title: "LineStringの座標リスト",
              minItems: 2,
              items: coordinate,
              examples: [
                [[160.0, 32.2175], [145.486252, 43.24743], [145.480118, 43.249398], [145.412432, 42.926476], [145.393203, 42.31716], [145.394284, 42.306034], [145.479425, 41.700239], [146.005674, 39.188776], [149.514356, 35.886453], [150.83862, 34.697293], [151.547974, 34.255494], [160.0, 29.000091]],
              ],
            }
          },
          required: [
            "type",
            "coordinates",
          ],
          additionalProperties: false,
        },
      ]
    },
    properties: {
      type: "object",
      title: "Featureのプロパティ",
      description: "空のオブジェクトです",
      const: {},
    },
  },
  required: [
    "type",
    "geometry",
    "properties",
  ],
  additionalProperties: false,
}

export interface JSONPolylineGeo {
  type: "FeatureCollection"
  features: {
    type: "Feature"
    geometry: {
      type: "LineString"
      coordinates: [number, number][]
    }
    properties: {
      start: string
      end: string
    }
  }[]
  properties: {
    name: string
    north: number
    south: number
    east: number
    west: number
  }
}

export const jsonPolyline: JSONSchemaType<JSONPolylineGeo> = {
  type: "object",
  title: "路線ポリライン",
  description: "Feature(LineString)で表現されるポリラインの集合FeatureCollectionです. フォーマットの詳細はGeoJSONに従います.",
  properties: {
    type: {
      type: "string",
      const: "FeatureCollection",
    },
    features: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        properties: {
          type: {
            type: "string",
            const: "Feature",
          },
          geometry: {
            type: "object",
            properties: {
              type: {
                type: "string",
                const: "LineString"
              },
              coordinates: {
                type: "array",
                minItems: 2,
                items: coordinate,
              }
            },
            required: [
              "type",
              "coordinates",
            ],
            additionalProperties: false,
          },
          properties: {
            type: "object",
            properties: {
              start: {
                type: "string",
                minLength: 1,
              },
              end: {
                type: "string",
                minLength: 1,
              },
            },
            required: ["start", "end"],
            additionalProperties: false,
          },
        },
        required: ["type", "geometry", "properties"],
        additionalProperties: false,
      },
    },
    properties: {
      type: "object",
      title: "路線ポリライン付加情報",
      description: "north, south, east, westでポイライン全体の範囲を示します.",
      properties: {
        name: {
          type: "string",
          minLength: 1,
          title: "路線名",
        },
        north: { type: "number" },
        south: { type: "number" },
        east: { type: "number" },
        west: { type: "number" },
      },
      required: ["name", "north", "south", "east", "west"],
      additionalProperties: false,
    }
  },
  required: [
    "type",
    "features",
    "properties",
  ],
  additionalProperties: false,
}

// TODO 独自フォーマット廃止の検討
export interface JSONPolylineSrc {
  name: string
  point_list: JSONPolylineSegment[]
}

export interface JSONPolylineSegment {
  start: string
  end: string
  points: JSONPolylinePoint[]
  extra?: boolean
  closed?: boolean
}

export interface JSONPolylinePoint {
  lng: number
  lat: number
}

export const jsonPolylineSrc: JSONSchemaType<JSONPolylineSrc> = {
  type: "object",
  properties: {
    name: stationLineName,
    point_list: {
      type: "array",
      items: {
        type: "object",
        properties: {
          start: { type: "string", minLength: 1 },
          end: { type: "string", minLength: 1 },
          points: {
            type: "array",
            items: {
              type: "object",
              properties: {
                lng: lng,
                lat: lat,
              },
              required: ["lng", "lat"],
              additionalProperties: false,
            },
          },
          extra: {
            type: "boolean",
            nullable: true,
          },
          closed: {
            type: "boolean",
            nullable: true,
          },
        },
        required: ["start", "end", "points"],
        additionalProperties: false,
      },
    },
  },
  required: ["name", "point_list",],
  // origin など不用な属性を許可
  additionalProperties: true,
}
