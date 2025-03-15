import { JSONSchemaType } from "ajv"
import { stationLineName } from "../ts/model/common"

export interface CSVEkimemo {
  code: number
  name: string
  /** https://ekimemo.com/database/ で駅・路線を指定するcode */
  ekimemo: number | null
}

export const csvEkimemo: JSONSchemaType<CSVEkimemo> = {
  type: "object",
  properties: {
    code: {
      type: "integer",
      minimum: 1000,
      maximum: 9999999,
    },
    name: stationLineName,
    ekimemo: {
      type: "integer",
      nullable: true,
    },
  },
  required: [
    "code",
    "name",
    "ekimemo",
  ],
  additionalProperties: false,
}