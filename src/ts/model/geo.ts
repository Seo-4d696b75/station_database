import { JSONSchemaType } from "ajv"

const coordinate: JSONSchemaType<[number, number]> = {
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
    coordinates: [[number, number][]]
  } | {
    type: "LineString"
    coordinates: [number, number][]
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

export interface JSONPolylineGeo {
  type: "FeatureCollection"
  features: {
    type: "Feature"
    geometry: {
      type: "LineString"
      coordinates: [number, number][]
    }
    properties: {
      start: string
      end: string
      closed?: boolean
    }
  }[]
  properties: {
    name: string
    north: number
    south: number
    east: number
    west: number
  }
}

export const jsonPolyline: JSONSchemaType<JSONPolylineGeo> = {
  type: "object",
  properties: {
    type: {
      type: "string",
      const: "FeatureCollection",
    },
    features: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        properties: {
          type: {
            type: "string",
            const: "Feature",
          },
          geometry: {
            type: "object",
            properties: {
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
          properties: {
            type: "object",
            properties: {
              start: {
                type: "string",
                minLength: 1,
              },
              end: {
                type: "string",
                minLength: 1,
              },
              closed: {
                type: "boolean",
                nullable: true,
              }
            },
            required: ["start", "end"],
            additionalProperties: false,
          },
        },
        required: ["type", "geometry", "properties"],
        additionalProperties: false,
      },
    },
    properties: {
      type: "object",
      properties: {
        name: {
          type: "string",
          minLength: 1,
        },
        north: { type: "number" },
        south: { type: "number" },
        east: { type: "number" },
        west: { type: "number" },
      },
      required: ["name", "north", "south", "east", "west"],
      additionalProperties: false,
    }
  },
  required: [
    "type",
    "features",
    "properties",
  ],
  additionalProperties: false,
}