import { JSONSchemaType } from "ajv";
import { stationLineName } from "./common";
import { jsonLine, JSONLine } from "./line";
import { jsonStation, JSONStation, stationCode } from "./station";

// 駅ナンバリングが追加されている
export interface JSONStationRegistration {
  code: number
  name: string
  numbering?: string[]
}

const jsonStationRegistrationNumbering: JSONSchemaType<string[]> = {
  type: "array",
  nullable: true,
  minItems: 1,
  uniqueItems: true,
  items: {
    type: "string",
    minLength: 1,
  },
  title: "駅ナンバリング",
  description: "各路線における駅のナンバリング",
  examples: [
    ["H75"],
  ],
}

const jsonStationRegistration: JSONSchemaType<JSONStationRegistration & JSONStation> = {
  type: "object",
  title: "駅オブジェクト(路線登録)",
  properties: {
    ...jsonStation.properties,
    numbering: jsonStationRegistrationNumbering,
  },
  required: [
    ...jsonStation.required,
  ],
  additionalProperties: false,
}

export interface JSONLineDetail extends JSONLine {
  station_list: (JSONStationRegistration & JSONStation)[]
}

export const jsonLineDetail: JSONSchemaType<JSONLineDetail> = {
  type: "object",
  title: "路線詳細オブジェクト",
  properties: {
    ...jsonLine.properties,
    station_list: {
      type: "array",
      minItems: 1,
      items: jsonStationRegistration,
      title: "登録駅リスト",
      description: "原則として駅メモ実装と同じ順序です",
    },
  },
  required: [
    ...jsonLine.required,
    "station_list",
  ],
  additionalProperties: false,
}

/** 
 * src/line/*.json 各路線の登録駅定義 
 */
export interface JSONLineDetailSrc {
  name: string
  station_list: JSONStationRegistrationSrc[]
}

/**
 * src/line/*.json 各路線の登録駅リストの要素
 */
export interface JSONStationRegistrationSrc {
  code: number
  name: string
  numbering?: string[]
  /**
   * 駅メモ実装には含まれない登録のみextra=trueを指定している
   * 
   * **駅自体のextra属性とは異なる**
   */
  extra?: boolean
}

export const jsonLineDetailSrc: JSONSchemaType<JSONLineDetailSrc> = {
  type: "object",
  title: "路線詳細ソースオブジェクト",
  properties: {
    name: stationLineName,
    station_list: {
      type: "array",
      minItems: 1,
      title: "登録駅リスト",
      items: {
        type: "object",
        title: "登録駅オブジェクト",
        description: "駅メモ実装には含まれない登録のみextra=trueを指定している",
        properties: {
          code: stationCode,
          name: stationLineName,
          numbering: {
            ...jsonStationRegistrationNumbering,
            nullable: true,
          },
          extra: {
            type: "boolean",
            nullable: true,
          },
        },
        required: [
          "code",
          "name",
        ],
        additionalProperties: false,
      },
    },
  },
  required: [
    "name",
    "station_list",
  ],
  additionalProperties: false,
}