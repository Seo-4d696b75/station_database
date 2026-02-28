import { JSONSchemaType } from "ajv"
import { stationLineName } from "../ts/model/common"

export interface CSVEkimemo {
  name: string
  /** https://ekimemo.com/database/ で駅・路線を指定するid */
  id: number
}

export const csvEkimemo: JSONSchemaType<CSVEkimemo> = {
  type: "object",
  properties: {
    name: stationLineName,
    id: {
      type: "integer",
    },
  },
  required: [
    "name",
    "id",
  ],
  additionalProperties: false,
}