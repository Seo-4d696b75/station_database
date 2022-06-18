import { JSONSchemaType } from "ajv"

export const stationLineId: JSONSchemaType<string> = {
  type: "string",
  pattern: "[0-9a-f]{6}",
}

export const stationLineName: JSONSchemaType<string> = {
  type: "string",
  minLength: 1,
}

export const kanaName: JSONSchemaType<string> = {
  type: "string",
  pattern: "[\\p{sc=Hiragana}ー・\\p{gc=P}\\s]+",
}

export const dateString = {
  type: "string" as "string",
  nullable: true as true,
  pattern: "[0-9]{4}-[0-9]{2}-[0-9]{2}",
}