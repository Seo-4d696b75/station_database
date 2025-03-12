import { JSONSchemaType } from "ajv"
import { Station } from "../validate/station"
import { dateStringPattern, kanaName, originalStationName, stationAttr, stationLineExtra, stationLineId, stationLineName } from "./common"
import { Dataset, hasExtra } from "./dataset"
import { jsonVoronoi, JSONVoronoiGeo } from "./geo"
import { lineCode } from "./line"
export const stationCode: JSONSchemaType<number> = {
  type: "integer",
  minimum: 100000,
  maximum: 9999999,
  title: "駅コード",
  description: "データセット内の駅を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません.",
  examples: [1110101, 100409],
}

export const stationLat: JSONSchemaType<number> = {
  type: "number",
  exclusiveMinimum: 26.0,
  exclusiveMaximum: 45.8,
  title: "駅座標（緯度）",
  description: "１０進小数で表記した緯度（小数点以下６桁）",
  examples: [41.773709, 37.754123]
}

export const stationLng: JSONSchemaType<number> = {
  type: "number",
  exclusiveMinimum: 127.5,
  exclusiveMaximum: 146.2,
  title: "駅座標（経度）",
  description: "１０進小数で表記した経度（小数点以下６桁）",
  examples: [140.726413, 140.459680]
}

export const prefectureCode: JSONSchemaType<number> = {
  type: "integer",
  minimum: 1,
  maximum: 47,
  title: "都道府県コード",
  description: "駅が所在する都道府県を表します.都道府県コードの値は全国地方公共団体コード（JIS X 0401）に従います.",
}

const lineCodes: JSONSchemaType<number[]> = {
  type: "array",
  items: lineCode,
  minItems: 1,
  uniqueItems: true,
  title: "駅が登録されている路線",
  description: "路線コードのリストで表現されます.各駅は必ずひとつ以上の路線に属するため、空のリストは許可しません.",
  examples: [
    [11101, 11119],
    [1004, 11231, 11216, 99213, 99215],
  ]
}

const postalCode: JSONSchemaType<string> = {
  type: "string",
  pattern: "^[0-9]{3}-[0-9]{4}$",
  title: "駅の所在地を表す郵便番号",
  description: "駅データ.jp由来の値、もしくは駅の緯度・軽度をGoogle Geocoding APIで自動検索した最も近い地点を指します.",
  examples: ["040-0063", "960-8031"],
}

const stationAddress: JSONSchemaType<string> = {
  type: "string",
  minLength: 1,
  title: "駅の所在地の住所",
  description: "駅データ.jp由来の値、もしくは駅の緯度・軽度をGoogle Geocoding APIで自動検索した最も近い地点を指します. データソースの違いにより住所表現の粒度が異なる場合があります.",
  examples: [
    "北海道函館市若松町１２-１３",
    "福島市栄町",
  ],
}

const openDate = {
  type: "string" as "string",
  nullable: true as true,
  pattern: dateStringPattern,
  title: "駅の開業日",
  description: "一部の駅のみ定義されます.",
  examples: ["1902-12-10"],
}

const closedDate = {
  type: "string" as "string",
  nullable: true as true,
  pattern: dateStringPattern,
  title: "駅の廃止日",
  description: "廃駅の一部の駅のみ定義されます. 現役駅の場合は定義されません.",
  examples: ["2022-03-12"],
}

export const stationClosed = {
  type: "boolean" as "boolean",
  nullable: true as true,
  title: "廃駅フラグ",
  description: "true: 廃駅, false: 現役駅 'main'データセットの一部では省略されます. 'undefined'の場合はfalseとして扱います."
}

export type JSONStation<D extends Dataset> = {
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
  postal_code: string
  address: string
  open_date?: string
  closed_date?: string
  voronoi: JSONVoronoiGeo
} & (D extends 'main' ? { attr: string } : { attr?: string, extra: boolean })

export function normalizeStation(json: JSONStation<Dataset>): Station {
  return {
    ...json,
    open_date: json.open_date ?? null,
    closed_date: json.closed_date ?? null,
    extra: hasExtra(json) ? json.extra : false,
    attr: json.attr ?? null,
  }
}

export const jsonStation = (dataset: Dataset): JSONSchemaType<JSONStation<typeof dataset>> =>
  dataset === 'main' ? jsonStationMain : jsonStationExtra

const jsonStationMain: JSONSchemaType<JSONStation<'main'>> = {
  title: "駅オブジェクト",
  description: "駅の情報",
  type: "object",
  examples: [
    { "code": 100409, "id": "7bfd6b", "name": "福島(福島)", "original_name": "福島", "name_kana": "ふくしま", "closed": false, "lat": 37.754123, "lng": 140.45968, "prefecture": 7, "lines": [1004, 11231, 11216, 99213, 99215], "attr": "heat", "postal_code": "960-8031", "address": "福島市栄町", "voronoi": { "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [[[140.436325, 37.741446], [140.441067, 37.754985], [140.446198, 37.756742], [140.501679, 37.758667], [140.510809, 37.752683], [140.527108, 37.739585], [140.534984, 37.729765], [140.436325, 37.741446]]] }, "properties": {} } },
  ],
  properties: {
    code: stationCode,
    id: stationLineId,
    name: stationLineName,
    original_name: originalStationName,
    name_kana: kanaName,
    closed: stationClosed,
    lat: stationLat,
    lng: stationLng,
    prefecture: prefectureCode,
    lines: lineCodes,
    attr: stationAttr,
    postal_code: postalCode,
    address: stationAddress,
    open_date: openDate,
    closed_date: closedDate,
    voronoi: jsonVoronoi,
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
    "attr",
    "postal_code",
    "address",
    "voronoi",
  ],
  additionalProperties: false,
}

const jsonStationExtra: JSONSchemaType<JSONStation<'extra'>> = {
  title: "駅オブジェクト",
  description: "駅の情報",
  type: "object",
  examples: [
    { "code": 100409, "id": "7bfd6b", "name": "福島(福島)", "original_name": "福島", "name_kana": "ふくしま", "closed": false, "lat": 37.754123, "lng": 140.45968, "prefecture": 7, "lines": [1004, 11231, 11216, 99213, 99215], "attr": "heat", "postal_code": "960-8031", "address": "福島市栄町", "voronoi": { "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [[[140.436325, 37.741446], [140.441067, 37.754985], [140.446198, 37.756742], [140.501679, 37.758667], [140.510809, 37.752683], [140.527108, 37.739585], [140.534984, 37.729765], [140.436325, 37.741446]]] }, "properties": {} } },
  ],
  properties: {
    code: stationCode,
    id: stationLineId,
    name: stationLineName,
    original_name: originalStationName,
    name_kana: kanaName,
    closed: stationClosed,
    lat: stationLat,
    lng: stationLng,
    prefecture: prefectureCode,
    lines: lineCodes,
    attr: {
      ...stationAttr,
      nullable: true,
    },
    postal_code: postalCode,
    address: stationAddress,
    open_date: openDate,
    closed_date: closedDate,
    voronoi: jsonVoronoi,
    extra: stationLineExtra,
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
    "extra",
  ],
  additionalProperties: false,
}

export const jsonStationList = (dataset: Dataset): JSONSchemaType<JSONStation<typeof dataset>[]> => ({
  type: "array",
  items: jsonStation(dataset),
  title: "駅リスト",
  description: "すべての駅を含みます"
})


export type CSVStation<D extends Dataset> = {
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
} & (D extends 'main' ? { attr: string } : { attr: string | null, extra: boolean })

export const csvStation = (dataset: Dataset): JSONSchemaType<CSVStation<typeof dataset>> =>
  dataset === 'main' ? csvStationMain : csvStationExtra

const csvStationMain: JSONSchemaType<CSVStation<'main'>> = {
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
    address: stationAddress,
    closed: stationClosed,
    open_date: openDate,
    closed_date: closedDate,
    attr: stationAttr,
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

const csvStationExtra: JSONSchemaType<CSVStation<'extra'>> = {
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
    address: stationAddress,
    closed: stationClosed,
    open_date: openDate,
    closed_date: closedDate,
    extra: stationLineExtra,
    attr: {
      ...stationAttr,
      nullable: true,
      enum: [
        ...stationAttr.enum,
        null,
      ],
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
    "extra",
  ],
  additionalProperties: false,
}