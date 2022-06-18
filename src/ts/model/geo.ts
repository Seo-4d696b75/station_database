import { JSONSchemaType } from "ajv"

const coordinate = {
  type: "array",
  minItems: 2,
  maxItems: 2,
  items: [
    // lng,latの順序
    {
      type: "number",
      minimum: 112,
      maximum: 160,
    },
    {
      type: "number",
      minimum: 20,
      maximum: 60,
    },
  ]
}

export interface JSONVoronoiGeo {
  type: "Feature"
  geometry: {
    type: "Polygon"
    coordinates: number[][][]
  } | {
    type: "LineString"
    coordinates: number[][]
  }
  properties: {}
}

export const jsonVoronoi: JSONSchemaType<JSONVoronoiGeo> = {
  type: "object",
  properties: {
    type: {
      type: "string",
      const: "Feature"
    },
    geometry: {
      type: "object",
      required: [
        "type",
        "coordinates",
      ],
      oneOf: [
        {
          type: "object",
          properties: {
            type: {
              type: "string",
              const: "Polygon"
            },
            coordinates: {
              type: "array",
              // ボロノイ領域は中空のないポリゴン
              minItems: 1,
              maxItems: 1,
              items: {
                type: "array",
                minItems: 3,
                items: coordinate,
              }
            },
          },
          required: [
            "type",
            "coordinates",
          ],
          additionalProperties: false,
        },
        {
          type: "object",
          properties: {
            // 外周部の一部は閉じていない
            type: {
              type: "string",
              const: "LineString"
            },
            coordinates: {
              type: "array",
              minItems: 2,
              items: coordinate,
            }
          },
          required: [
            "type",
            "coordinates",
          ],
          additionalProperties: false,
        },
      ]
    },
    properties: {
      type: "object",
      const: {},
    },
  },
  required: [
    "type",
    "properties",
  ],
  additionalProperties: false,
}