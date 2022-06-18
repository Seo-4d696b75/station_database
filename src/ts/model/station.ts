import { dateString, kanaName, stationLineId, stationLineName } from "./common"
import { lineCode } from "./line"

export const stationCode = {
  type: "integer",
  minimum: 100000,
  maximum: 9999999,
}

const stationLat = {
  type: "number",
  exclusiveMinimum: 26.0,
  exclusiveMaximum: 45.8,
}

const stationLng = {
  type: "number",
  exclusiveMinimum: 127.5,
  exclusiveMaximum: 146.2,
}

const prefectureCode = {
  type: "integer",
  minimum: 1,
  maximum: 47,
}

const lineCodes = {
  type: "array",
  items: lineCode,
  minItems: 1,
  uniqueItems: true,
}

const stationAttr = {
  type: "string",
  enum: [
    "eco",
    "heat",
    "cool",
    "unknown",
  ]
}

const postalCode = {
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

const polygonGeometry = {
  type: "object",
  properties: {
    type: { const: "Polygon" },
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
}

const lineGeometry = {
  type: "object",
  properties: {
    type: { const: "LineString" },
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
}

const voronoi = {
  type: "object",
  properties: {
    type: { const: "Feature" },
    geometry: {
      oneOf: [
        polygonGeometry,
        lineGeometry, // 外周部の一部は閉じていない
      ]
    },
    properties: { const: {} },
  },
  required: [
    "type",
    "properties",
  ],
  additionalProperties: false,
}

export const station = {
  type: "object",
  properties: {
    code: stationCode,
    id: stationLineId,
    name: stationLineName,
    original_name: stationLineName,
    name_kana: kanaName,
    closed: { type: "boolean"},
    lat: stationLat,
    lng: stationLng,
    prefecture: prefectureCode,
    lines: lineCodes,
    attr: stationAttr,
    postal_code: postalCode,
    address: {type: "string", minLength: 1},
    open_date: dateString,
    closed_date: dateString,
    voronoi: voronoi,
    impl: {type: "boolean"},
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

export const stationList = {
  type: "array",
  items: station,
}