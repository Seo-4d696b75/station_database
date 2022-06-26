import { JSONSchemaType } from "ajv"
import { stationLineName } from "./common"
import { jsonPolyline, JSONPolylineGeo } from "./geo"
import { jsonLine, JSONLine } from "./line"
import { JSONStationRegistration } from "./lineDetail"
import { jsonStationList, JSONStation, stationCode, stationLat, stationLng, jsonStation } from "./station"
import { JSONKdTreeNode, JSONKdTreeSegmentNode } from "./tree"

export interface AllData {
  version: number
  stations: StationNext[]
  lines: LineDetailSimple[]
  tree_segments: KdTreeSegment[]
}

//////////////////
// stations //////
//////////////////

interface StationNext extends JSONStation {
  next: number[]
}

const jsonStationNext: JSONSchemaType<StationNext> = {
  type: "object",
  properties: {
    ...jsonStation.properties,
    next: {
      type: "array",
      items: stationCode,
      minItems: 1,
      uniqueItems: true,
    }
  },
  required: [
    ...jsonStation.required,
    "next"
  ],
  additionalProperties: false,
}

//////////////////
// liens /////////
//////////////////

interface LineDetailSimple extends JSONLine {
  station_list: JSONStationRegistration[]
  polyline_list?: JSONPolylineGeo
}

const jsonLineDetailSimple: JSONSchemaType<LineDetailSimple> = {
  type: "object",
  properties: {
    ...jsonLine.properties,
    station_list: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        properties: {
          code: stationCode,
          name: stationLineName,
          numbering: {
            type: "array",
            nullable: true,
            minItems: 1,
            items: {
              type: "string",
              minLength: 1,
            },
          },
        },
        required: [
          "code",
          "name",
        ],
        additionalProperties: false,
      },
    },
    polyline_list: jsonPolyline,
  },
  required: [
    ...jsonLine.required,
    "station_list",
  ],
  additionalProperties: false,
}


////////////////////
// tree_segments ///
////////////////////

interface KdTreeSegment {
  name: string
  root: number
  node_list: JSONKdTreeSegmentNode[]
}

const jsonKdTreeSegment: JSONSchemaType<KdTreeSegment> = {
  type: "object",
  properties: {
    name: {
      type: "string",
      minLength: 1,
    },
    root: stationCode,
    node_list: {
      type: "array",
      minItems: 1,
      items: {
        type: "object",
        properties: {
          code: stationCode,
          name: stationLineName,
          lat: stationLat,
          lng: stationLng,
          left: {
            ...stationCode,
            nullable: true,
          },
          right: {
            ...stationCode,
            nullable: true,
          },
          segment: {
            type: "string",
            minLength: 1,
            nullable: true,
          },
        },
        required: ["code", "name", "lat", "lng"],
        additionalProperties: false,
      },
    }
  },
  required: ["name", "root", "node_list"],
  additionalProperties: false,
}

//////////////////
// all data //////
//////////////////

export const jsonAllData: JSONSchemaType<AllData> = {
  type: "object",
  properties: {
    version: { type: "integer" },
    stations: {
      type: "array",
      items: jsonStationNext,
    },
    lines: {
      type: "array",
      items: jsonLineDetailSimple,
    },
    tree_segments: {
      type: "array",
      items: jsonKdTreeSegment,
    }
  },
  required: ["version", "stations", "lines", "tree_segments"],
  additionalProperties: false
}