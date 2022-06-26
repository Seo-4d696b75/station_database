import { JSONSchemaType } from "ajv"
import { stationLineName } from "./common"
import { JSONStation, jsonStation, stationCode, stationLat, stationLng } from "./station"

export interface JSONKdTreeNode {
  code: number
  name: string
  lat: number
  lng: number
  left?: number
  right?: number
}

const jsonKdTreeNode: JSONSchemaType<JSONKdTreeNode> = {
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
  },
  required: ["code", "name", "lat", "lng"],
  additionalProperties: false,
}

export interface JSONKdTree {
  root: number
  node_list: JSONKdTreeNode[]
}

export const jsonKdTree: JSONSchemaType<JSONKdTree> = {
  type: "object",
  properties: {
    root: {
      type: "integer"
    },
    node_list: {
      type: "array",
      minItems: 1,
      items: jsonKdTreeNode,
    }
  },
  required: ["root", "node_list"],
  additionalProperties: false,
}

export interface JSONKdTreeSegmentNode extends JSONKdTreeNode {
  segment?: string
}

export type JSONStationNode = JSONStation & JSONKdTreeSegmentNode

const jsonStationNode: JSONSchemaType<JSONStationNode> = {
  type: "object",
  properties: {
    ...jsonStation.properties,
    ...jsonKdTreeNode.properties,
    segment: {
      type: "string",
      minLength: 1,
      nullable: true,
    },
  },
  required: jsonStation.required,
  additionalProperties: false,
}

export interface JSONKdTreeSegment {
  name: string
  root: number
  node_list: JSONStationNode[]
}

export const jsonKdTreeSegment: JSONSchemaType<JSONKdTreeSegment> = {
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
      items: jsonStationNode,
    }
  },
  required: ["name", "root", "node_list"],
  additionalProperties: false,
}