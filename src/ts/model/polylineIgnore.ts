import { JSONSchemaType } from "ajv"

export interface PolylineIgnore {
  name: string
}

export const csvPolylineIgnore: JSONSchemaType<PolylineIgnore> = {
  type: "object",
  properties: {
    name: {
      type: "string",
      minLength: 1,
    },
  },
  required: [
    "name",
  ],
  additionalProperties: false,
}