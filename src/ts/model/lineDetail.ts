import { JSONSchemaType } from "ajv";
import { jsonLine, JSONLine } from "./line";
import { jsonStation, JSONStation } from "./station";

// 駅ナンバリングが追加されている
export interface JSONStationRegistration {
  code: number
  name: string
  numbering?: string[]
}

const jsonStationRegistration: JSONSchemaType<JSONStationRegistration & JSONStation> = {
  type: "object",
  title: "駅オブジェクト(路線登録)",
  properties: {
    ...jsonStation.properties,
    numbering: {
      type: "array",
      nullable: true,
      minItems: 1,
      items: {
        type: "string",
        minLength: 1,
      },
      title: "駅ナンバリング",
      description: "各路線における駅のナンバリング",
      examples: [
        ["H75"],
      ],
    },
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