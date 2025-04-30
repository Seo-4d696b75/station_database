import { JSONSchemaType } from "ajv"
import { dateStringPattern, kanaName, stationLineExtra, stationLineName } from "./common"
import { Dataset, WithExtra } from "./dataset"

export const lineCode: JSONSchemaType<number> = {
  type: "integer",
  minimum: 1000,
  maximum: 99999,
  title: "路線コード",
  description: "データセット内の路線を一意に区別する値. 駅・路線IDとは異なり、別バージョンのデータセット間では一貫性を保証しません."
}

const lineId: JSONSchemaType<number> = {
  type: "integer",
  minimum: 1,
  title: "路線ID",
  description: "路線の識別子. 路線コードとは異なり、別バージョンのデータセット間でも一貫性を保証します（駅メモ実装における「同じ」路線のIDは異なるデータセットでも同じIDになります）. IDは駅メモ公式Webサイトの「駅の思い出」ページのURL https://ekimemo.com/database/line/{id} に対応しています. 独自追加の廃線のIDは2000番台の連番を使用しています.",
  examples: [
    1,
    2,
  ],
}

export type JSONLine<D extends Dataset> = WithExtra<D, {
  code: number
  id: number
  name: string
  name_kana: string
  name_formal?: string
  station_size: number
  company_code?: number
  closed: boolean
  color?: string
  symbol?: string
  closed_date?: string
}>

export const jsonLine = (dataset: Dataset): JSONSchemaType<JSONLine<typeof dataset>> => dataset === 'main' ? jsonLineMain : {
  ...jsonLineMain,
  properties: {
    ...jsonLineMain.properties,
    extra: stationLineExtra,
  },
  required: [
    ...jsonLineMain.required,
    'extra',
  ],
}

const jsonLineMain: JSONSchemaType<JSONLine<'main'>> = {
  type: "object",
  title: "路線オブジェクト",
  examples: [
    { "code": 11319, "id": "2d2b3a", "name": "JR東北本線(宇都宮線)", "name_kana": "じぇいあーるとうほくほんせん", "name_formal": "JR東北本線", "station_size": 33, "company_code": 2, "closed": false, "color": "#F68B1E", "symbol": "JU" },
  ],
  properties: {
    code: lineCode,
    id: lineId,
    name: stationLineName,
    name_kana: kanaName,
    name_formal: {
      type: "string",
      nullable: true,
      minLength: 1,
      title: "路線の正式名称",
      description: "nameと一致する場合はundefined",
      examples: ["JR東北本線"],
    },
    station_size: {
      type: "integer",
      minimum: 1,
      title: "登録駅数",
      description: "かならず１駅以上登録があります",
      examples: [3, 24]
    },
    company_code: {
      type: "integer",
      nullable: true,
      minimum: 0,
      title: "事業者コード",
    },
    closed: {
      type: "boolean",
      title: "廃線フラグ",
      description: "廃線の場合はtrue",
    },
    color: {
      type: "string",
      nullable: true,
      pattern: "^#[0-9A-F]{6}$",
      title: "路線カラー",
      description: "RGBチャネル16進数",
      examples: ["#F68B1E"],
    },
    symbol: {
      type: "string",
      nullable: true,
      minLength: 1,
      title: "路線記号",
      examples: ["JU"]
    },
    closed_date: {
      type: "string",
      nullable: true,
      pattern: dateStringPattern,
      title: "路線の廃止日",
      description: "廃線の一部のみ定義されます. 現役駅の場合は定義されません.",
      examples: ["2015-03-14"],
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

export const jsonLineList = <D extends Dataset>(dataset: D): JSONSchemaType<JSONLine<D>[]> => ({
  type: "array",
  items: jsonLine(dataset),
  title: "路線リスト",
  description: "すべての路線を含むリスト",
})

export type CSVLine<D extends Dataset> = WithExtra<D, {
  code: number
  id: number
  name: string
  name_kana: string
  name_formal: string | null
  station_size: number
  company_code: number | null
  color: string | null
  symbol: string | null
  closed: boolean
  closed_date: string | null
}>

export const csvLine = (dataset: Dataset): JSONSchemaType<CSVLine<typeof dataset>> => dataset === 'main' ? csvLineMain : {
  ...csvLineMain,
  properties: {
    ...csvLineMain.properties,
    extra: stationLineExtra,
  },
  required: [
    ...csvLineMain.required,
    'extra',
  ],
}

const csvLineMain: JSONSchemaType<CSVLine<'main'>> = {
  type: "object",
  properties: {
    code: lineCode,
    id: lineId,
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
      pattern: "^#[0-9A-F]{6}$"
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