import { JSONSchemaType } from "ajv";
import { kanaName, originalStationName, stationLineName } from "./common";
import { Dataset } from "./dataset";
import { jsonLine, JSONLine } from "./line";
import { jsonStation, JSONStation, prefectureCode, stationClosed, stationCode, stationId, stationLat, stationLng } from "./station";

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

const jsonStationRegistration = (dataset: Dataset): JSONSchemaType<JSONStationRegistration & JSONStation<typeof dataset>> => ({
  type: "object",
  title: "駅オブジェクト(路線登録)",
  properties: {
    // 順序に注意
    code: stationCode,
    id: stationId,
    name: stationLineName,
    original_name: originalStationName,
    name_kana: kanaName,
    closed: stationClosed,
    lat: stationLat,
    lng: stationLng,
    prefecture: prefectureCode,
    numbering: jsonStationRegistrationNumbering,
    ...jsonStation(dataset).properties,
  },
  required: [
    ...jsonStation(dataset).required,
  ],
  additionalProperties: false,
})

export type JSONLineDetail<T extends Dataset> = JSONLine<T> & {
  station_list: (JSONStationRegistration & JSONStation<T>)[]
}

export const jsonLineDetail = (dataset: Dataset): JSONSchemaType<JSONLineDetail<typeof dataset>> => {
  const line = jsonLine(dataset)
  const { closed_date, extra, ...rest } = line.properties
  return {
    type: "object",
    title: "路線詳細オブジェクト",
    properties: {
      // 順序に注意
      ...rest,
      station_list: {
        type: "array",
        minItems: 1,
        items: jsonStationRegistration(dataset),
        title: "登録駅リスト",
        description: "原則として駅メモ実装と同じ順序です",
      },
      ...line.properties,
    },
    required: [
      ...line.required,
      "station_list",
    ],
    additionalProperties: false,
  }
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
export interface JSONStationRegistrationSrc extends JSONStationRegistration {
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