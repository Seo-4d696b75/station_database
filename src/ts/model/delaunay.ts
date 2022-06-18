import { JSONSchemaType } from "ajv"
import { stationLineName } from "./common"
import { stationCode, stationLat, stationLng } from "./station"

export interface DelaunayStation {
  code: number
  name: string
  lat: number
  lng: number
  next: number[]
}

export const jsonDelaunayList: JSONSchemaType<DelaunayStation[]> = {
  type: "array",
  items: {
    type: "object",
    properties: {
      code: stationCode,
      name: stationLineName,
      lat: stationLat,
      lng: stationLng,
      next: {
        type: "array",
        items: stationCode,
        minItems: 1,
        uniqueItems: true,
      }
    },
    required: [
      "code",
      "name",
      "lat",
      "lng",
      "next"
    ],
    additionalProperties: false,
  }
}