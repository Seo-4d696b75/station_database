import { JSONSchemaType } from "ajv"
import { dateString, kanaName, stationLineId, stationLineName } from "./common"
import { lineCode } from "./line"

export const stationCode: JSONSchemaType<number> = {
  type: "integer",
  minimum: 100000,
  maximum: 9999999,
}

const stationLat: JSONSchemaType<number> = {
  type: "number",
  exclusiveMinimum: 26.0,
  exclusiveMaximum: 45.8,
}

const stationLng: JSONSchemaType<number> = {
  type: "number",
  exclusiveMinimum: 127.5,
  exclusiveMaximum: 146.2,
}

const prefectureCode: JSONSchemaType<number> = {
  type: "integer",
  minimum: 1,
  maximum: 47,
}

const lineCodes: JSONSchemaType<number[]> = {
  type: "array",
  items: lineCode,
  minItems: 1,
  uniqueItems: true,
}

const stationAttr: JSONSchemaType<string | undefined> = {
  type: "string",
  enum: [
    "eco",
    "heat",
    "cool",
    "unknown",
  ]
}

const postalCode: JSONSchemaType<string> = {
  type: "string",
  pattern: "[0-9]{3}-[0-9]{4}"
}

const coordinate = {
  type: "array",
  minItems: 2,
  maxItems: 2,
  items: [
    // lng,latの順序
    {
      type: "number",
      minimum: 112,
      maximum: 160,
    },
    {
      type: "number",
      minimum: 20,
      maximum: 60,
    },
  ]
}

export interface JSONVoronoiGeo {
  type: "Feature"
  geometry: {
    type: "Polygon"
    coordinates: number[][][]
  } | {
    type: "LineString"
    coordinates: number[][]
  }
  properties: {}
}

const voronoi: JSONSchemaType<JSONVoronoiGeo> = {
  type: "object",
  properties: {
    type: {
      type: "string",
      const: "Feature"
    },
    geometry: {
      type: "object",
      required: [
        "type",
        "coordinates",
      ],
      oneOf: [
        {
          type: "object",
          properties: {
            type: {
              type: "string",
              const: "Polygon"
            },
            coordinates: {
              type: "array",
              // ボロノイ領域は中空のないポリゴン
              minItems: 1,
              maxItems: 1,
              items: {
                type: "array",
                minItems: 3,
                items: coordinate,
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
          properties: {
            // 外周部の一部は閉じていない
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
      ]
    },
    properties: {
      type: "object",
      const: {},
    },
  },
  required: [
    "type",
    "properties",
  ],
  additionalProperties: false,
}

export interface JSONStation {
  code: number
  id: string
  name: string
  original_name: string
  name_kana: string
  closed: boolean
  lat: number
  lng: number
  prefecture: number
  lines: number[],
  attr?: string
  postal_code: string
  address: string
  open_date?: string
  closed_date?: string
  voronoi: JSONVoronoiGeo
  impl?: boolean
}

export const jsonStation: JSONSchemaType<JSONStation> = {
  type: "object",
  properties: {
    code: stationCode,
    id: stationLineId,
    name: stationLineName,
    original_name: stationLineName,
    name_kana: kanaName,
    closed: { type: "boolean" },
    lat: stationLat,
    lng: stationLng,
    prefecture: prefectureCode,
    lines: lineCodes,
    attr: {
      type: "string",
      nullable: true,
      enum: [
        "eco",
        "heat",
        "cool",
        "unknown",
      ]
    },
    postal_code: postalCode,
    address: { type: "string", minLength: 1 },
    open_date: dateString,
    closed_date: dateString,
    voronoi: voronoi,
    impl: { type: "boolean", nullable: true },
  },
  required: [
    "code",
    "id",
    "name",
    "original_name",
    "name_kana",
    "closed",
    "lat",
    "lng",
    "prefecture",
    "lines",
    "postal_code",
    "address",
    "voronoi",
  ],
  additionalProperties: false,
}

export const jsonStationList: JSONSchemaType<JSONStation[]> = {
  type: "array",
  items: jsonStation,
}