import { JSONSchemaType } from "ajv"
import { Station } from "../validate/station"
import { dateString, kanaName, stationLineId, stationLineName } from "./common"
import { jsonVoronoi, JSONVoronoiGeo } from "./geo"
import { lineCode } from "./line"

export const stationCode: JSONSchemaType<number> = {
  type: "integer",
  minimum: 100000,
  maximum: 9999999,
}

export const stationLat: JSONSchemaType<number> = {
  type: "number",
  exclusiveMinimum: 26.0,
  exclusiveMaximum: 45.8,
}

export const stationLng: JSONSchemaType<number> = {
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

const postalCode: JSONSchemaType<string> = {
  type: "string",
  pattern: "[0-9]{3}-[0-9]{4}"
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

export function normalizeStation(json: JSONStation): Station {
  return {
    ...json,
    open_date: json.open_date ?? null,
    closed_date: json.closed_date ?? null,
    impl: json.impl === undefined || json.impl,
    attr: json.attr ?? null,
  }
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
    voronoi: jsonVoronoi,
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


export interface CSVStation {
  code: number
  id: string
  name: string
  original_name: string
  name_kana: string
  lat: number
  lng: number
  prefecture: number
  postal_code: string
  address: string
  closed: boolean
  open_date: string | null
  closed_date: string | null
  impl?: boolean
  attr: string | null
}

export const csvStation: JSONSchemaType<CSVStation> = {
  type: "object",
  properties: {
    code: stationCode,
    id: stationLineId,
    name: stationLineName,
    original_name: stationLineName,
    name_kana: kanaName,
    lat: stationLat,
    lng: stationLng,
    prefecture: prefectureCode,
    postal_code: postalCode,
    address: { type: "string", minLength: 1 },
    closed: { type: "boolean" },
    open_date: dateString,
    closed_date: dateString,
    impl: { type: "boolean", nullable: true },
    attr: {
      type: "string",
      nullable: true,
      enum: [
        "eco",
        "heat",
        "cool",
        "unknown",
        null,
      ]
    },
  },
  required: [
    "code",
    "id",
    "name",
    "original_name",
    "name_kana",
    "lat",
    "lng",
    "prefecture",
    "postal_code",
    "address",
    "closed",
    "open_date",
    "closed_date",
    "attr",
  ],
  additionalProperties: false,
}