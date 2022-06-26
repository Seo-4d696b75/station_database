import { JSONSchemaType } from "ajv"
import { Line } from "../validate/line"
import { dateStringPattern, kanaName, stationLineId, stationLineImpl, stationLineName } from "./common"

export const lineCode: JSONSchemaType<number> = {
  type: "integer",
  minimum: 1000,
  maximum: 99999,
  title: "路線コード",
  description: "データセット内の路線を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません."
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

export function normalizeLine(raw: JSONLine): Line {
  return {
    code: raw.code,
    id: raw.id,
    name: raw.name,
    name_kana: raw.name_kana,
    name_formal: raw.name_formal ?? null,
    station_size: raw.station_size,
    company_code: raw.company_code ?? null,
    closed: raw.closed,
    color: raw.color ?? null,
    symbol: raw.symbol ?? null,
    closed_date: raw.closed_date ?? null,
    impl: raw.impl === undefined || raw.impl
  }
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
    closed_date: {
      type: "string",
      nullable: true,
      pattern: dateStringPattern,
      title: "路線の廃止日",
      description: "廃線の一部のみ定義されます. 現役駅の場合は定義されません."
    },
    impl: stationLineImpl,
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
    closed_date: {
      type: "string",
      nullable: true,
      pattern: dateStringPattern,
    },
    impl: stationLineImpl,
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