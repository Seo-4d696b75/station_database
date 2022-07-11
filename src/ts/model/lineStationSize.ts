import { JSONSchemaType } from "ajv"

export interface LineStationSize {
  name: string
  size: number
}

export const csvLineStationSize: JSONSchemaType<LineStationSize> = {
  type: "object",
  properties: {
    name: {
      type: "string",
      minLength: 1,
    },
    size: {
      type: "integer",
      minimum: 1,
    },
  },
  required: [
    "name",
    "size",
  ],
  additionalProperties: false,
}