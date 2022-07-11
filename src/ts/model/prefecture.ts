import { JSONSchemaType } from "ajv";

export interface Prefecture {
  code: number
  name: string
  size: number
}

export const csvPrefecture: JSONSchemaType<Prefecture> = {
  type: "object",
  properties: {
    code: {
      type: "integer",
      minimum: 1,
      maximum: 47,
    },
    name: {
      type: "string",
      minLength: 3,
      maxLength: 4,
    },
    size: {
      type: "integer",
      minimum: 1,
    },
  },
  additionalProperties: false,
  required: [
    "code",
    "name",
    "size",
  ]
}