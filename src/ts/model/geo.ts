import { JSONSchemaType } from "ajv"

const coordinate: JSONSchemaType<[number, number]> = {
  type: "array",
  minItems: 2,
  maxItems: 2,
  items: [
    // lng,latの順序
    {
      type: "number",
      minimum: 112,
      maximum: 160,
      title: "経度",
    },
    {
      type: "number",
      minimum: 20,
      maximum: 60,
      title: "緯度"
    },
  ],
  title: "座標点",
  description : "緯度・経度の組み合わせで座標を表します. リストの長さは２で固定で、経度・緯度の順番です."
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
          properties: {
            type: {
              type: "string",
              const: "Polygon"
            },
            coordinates: {
              type: "array",
              title: "Polygonの座標リスト",
              description: "ボロノイ範囲は中空のないポリゴンのため、長さ１のリスト",
              // ボロノイ領域は中空のないポリゴン
              minItems: 1,
              maxItems: 1,
              items: {
                type: "array",
                minItems: 3,
                items: coordinate,
                title: "Polygonの座標リスト[0]",
                description : "始点と終点の座標が一致します",
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
      closed?: boolean
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
              closed: {
                type: "boolean",
                nullable: true,
              }
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
      properties: {
        name: {
          type: "string",
          minLength: 1,
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