import { dateString, kanaName, stationLineId, stationLineName } from "./common"

export const lineCode = {
  type: "integer",
  minimum: 1000,
  maximum: 99999,
}

const lineColor = {
  type: "string",
  pattern: "#[0-9A-F]{6}"
}

const stationSize = {
  type: "integer",
  minimum: 1,
}

const companyCode = {
  type: "integer",
  minimum: 0,
}

const lineSymbol = {
  type: "string",
  minLength: 1,
}

export const jsonLine = {
  type: "object",
  properties: {
    code: lineCode,
    id: stationLineId,
    name: stationLineName,
    name_kana: kanaName,
    name_formal: stationLineName,
    station_size: stationSize,
    company_code: companyCode,
    closed: { type: "boolean" },
    color: lineColor,
    symbol: lineSymbol,
    closed_date: dateString,
    impl: { type: "boolean" },
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

export const jsonLineList = {
  type: "array",
  items: jsonLine,
}