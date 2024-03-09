import { JSONSchemaType } from "ajv"
import { lineCode } from "./line"
import { stationCode } from "./station"

export interface StationRegister {
  station_code: number
  line_code: number
  index: number
  numbering: string | null
  extra?: boolean
}

export const csvRegister: JSONSchemaType<StationRegister> = {
  type: "object",
  properties: {
    station_code: stationCode,
    line_code: lineCode,
    index: {
      type: "integer",
      minimum: 1,
    },
    numbering: {
      type: "string",
      nullable: true,
    },
    extra: {
      type: "boolean",
      nullable: true,
    }
  },
  required: [
    "station_code",
    "line_code",
    "numbering",
    "index"
  ],
  additionalProperties: false,
}