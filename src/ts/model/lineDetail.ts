import { JSONSchemaType } from "ajv";
import { jsonPolyline, JSONPolylineGeo } from "./geo";
import { jsonLine, JSONLine } from "./line";
import { jsonStation, JSONStation } from "./station";

// 駅ナンバリングが追加されている
interface JSONStationRegistration extends JSONStation {
  numbering?: string[]
}

const jsonStationRegistration: JSONSchemaType<JSONStationRegistration> = {
  type: "object",
  properties: {
    ...jsonStation.properties,
    numbering: {
      type: "array",
      minItems: 1,
      items: {
        type: "string",
        minLength: 1,
      },
    },
  },
  required: [
    ...jsonStation.required,
  ],
  additionalProperties: false,
}

export interface JSONLineDetail extends JSONLine {
  station_list: JSONStationRegistration[]
  polyline_list?: JSONPolylineGeo
}

export const jsonLineDetail: JSONSchemaType<JSONLineDetail> = {
  type: "object",
  properties: {
    ...jsonLine.properties,
    station_list: {
      type: "array",
      minItems: 1,
      items: jsonStationRegistration,
    },
    polyline_list: jsonPolyline,
  },
  required: [
    ...jsonLine.required,
    "station_list",
  ],
  additionalProperties: false,
}