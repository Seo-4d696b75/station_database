import { JSONSchemaType } from "ajv"
import { Dataset, WithExtra } from "./dataset"
import { lineCode } from "./line"
import { stationCode } from "./station"

export type CSVStationRegister<D extends Dataset> = WithExtra<D, {
  station_code: number
  line_code: number
  index: number
  numbering: string | null
}>

export const csvRegister = (dataset: Dataset): JSONSchemaType<CSVStationRegister<typeof dataset>> => dataset === 'main' ? csvRegisterMain : {
  ...csvRegisterMain,
  properties: {
    ...csvRegisterMain.properties,
    extra: { type: "boolean" },
  },
  required: [
    ...csvRegisterMain.required,
    'extra',
  ],
}

const csvRegisterMain: JSONSchemaType<CSVStationRegister<'main'>> = {
  type: "object",
  properties: {
    station_code: stationCode,
    line_code: lineCode,
    index: {
      type: "integer",
      minimum: 1,
      title: "駅の登録順序",
      description: "駅メモにおける駅の登録順序",
    },
    numbering: {
      type: "string",
      nullable: true,
      title: "駅ナンバリング",
      description: "各路線における駅のナンバリング.複数路線のナンバリングを持つ場合は'/'で連結して表現します",
      examples: [
        "H75",
        "H75/H76",
      ],
    },
  },
  required: [
    "station_code",
    "line_code",
    "numbering",
    "index",
  ],
  additionalProperties: false,
}