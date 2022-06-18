import { JSONSchemaType } from "ajv"
import { dateString, kanaName, stationLineId, stationLineName } from "./common"

export const lineCode: JSONSchemaType<number> = {
  type: "integer",
  minimum: 1000,
  maximum: 99999,
}

export interface JSONLine {
  code: number
  id: string
  name: string
  name_kana: string
  name_formal?: string
  station_size: number
  company_code?: number
  closed: boolean
  color?: string
  symbol?: string
  closed_date?: string
  impl?: boolean
}

export const jsonLine: JSONSchemaType<JSONLine> = {
  type: "object",
  properties: {
    code: lineCode,
    id: stationLineId,
    name: stationLineName,
    name_kana: kanaName,
    name_formal: {
      type: "string",
      nullable: true,
      minLength: 1
    },
    station_size: {
      type: "integer",
      minimum: 1,
    },
    company_code: {
      type: "integer",
      nullable: true,
      minimum: 0,
    },
    closed: {
      type: "boolean",
    },
    color: {
      type: "string",
      nullable: true,
      pattern: "#[0-9A-F]{6}"
    },
    symbol: {
      type: "string",
      nullable: true,
      minLength: 1,
    },
    closed_date: dateString,
    impl: {
      type: "boolean",
      nullable: true,
    },
  },
  required: [
    "code",
    "id",
    "name",
    "name_kana",
    "station_size",
    "closed",
  ],
  additionalProperties: false,
}

export const jsonLineList: JSONSchemaType<JSONLine[]> = {
  type: "array",
  items: jsonLine,
}

export interface CSVLine {
  code: number
  id: string
  name: string
  name_kana: string
  name_formal: string | null
  station_size: number
  company_code: number | null
  color: string | null
  symbol: string | null
  closed: boolean
  closed_date: string | null
  impl?: boolean
}

export const csvLine: JSONSchemaType<CSVLine> = {
  type: "object",
  properties: {
    code: lineCode,
    id: stationLineId,
    name: stationLineName,
    name_kana: kanaName,
    name_formal: {
      type: "string",
      nullable: true,
      minLength: 1
    },
    station_size: {
      type: "integer",
      minimum: 1,
    },
    company_code: {
      type: "integer",
      nullable: true,
      minimum: 0,
    },
    color: {
      type: "string",
      nullable: true,
      pattern: "#[0-9A-F]{6}"
    },
    symbol: {
      type: "string",
      nullable: true,
      minLength: 1,
    },
    closed: {
      type: "boolean",
    },
    closed_date: dateString,
    impl: {
      type: "boolean",
      nullable: true,
    },
  },
  required: [
    "code",
    "id",
    "name",
    "name_kana",
    "name_formal",
    "station_size",
    "company_code",
    "color",
    "symbol",
    "closed",
    "closed_date"
  ],
  additionalProperties: false,
}