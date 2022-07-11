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
  title: "探索木の頂点",
  description: "駅の座標点を頂点として扱います. left, rightで下に続く子頂点を表します.",
  properties: {
    code: stationCode,
    name: stationLineName,
    lat: stationLat,
    lng: stationLng,
    left: {
      ...stationCode,
      nullable: true,
      title: "子頂点の駅コード(left)",
      description: "緯度または経度の値がこの駅の座標より小さい頂点の駅コード"
    },
    right: {
      ...stationCode,
      nullable: true,
      title: "子頂点の駅コード(right)",
      description: "緯度または経度の値がこの駅の座標より大きい頂点の駅コード"
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
  title: "探索木",
  description: "駅の座標点に従い近傍を高速に探索するためのデータ構造(kd-tree)を定義します.",
  properties: {
    root: {
      type: "integer",
      title: "ルート駅コード",
      description: "kd-treeのルートに位置する頂点の駅コード. node_listに該当する頂点（駅）が必ず含まれます.",
    },
    node_list: {
      type: "array",
      minItems: 1,
      items: jsonKdTreeNode,
      title: "頂点リスト",
      description: "kd-treeを構成する頂点（駅）のリスト",
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
  title: "探索部分木の頂点",
  description: "駅の座標点を頂点として扱います. left, rightで下に続く子頂点を表します.",
  properties: {
    ...jsonStation.properties,
    ...jsonKdTreeNode.properties,
    segment: {
      type: "string",
      minLength: 1,
      nullable: true,
      title: "部分木の名前",
      description: "segmentが定義されている場合、指定された名前の部分木がこの頂点の下に続きます.",
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
  title: "探索部分木",
  description: "駅を座標点から探索するためのデータ構造(kd-tree)の部分木",
  properties: {
    name: {
      type: "string",
      minLength: 1,
      title: "部分木の名前",
      description: "部分木の名前はファイル名と一致します ${name}.json",
    },
    root: {
      type: "integer",
      title: "ルート駅コード",
      description: "部分木のルートに位置する頂点の駅コード. node_listに該当する頂点（駅）が必ず含まれます.",
    },
    node_list: {
      type: "array",
      minItems: 1,
      items: jsonStationNode,
      title: "頂点リスト",
      description: "部分木を構成する頂点（駅）のリスト",
    }
  },
  required: ["name", "root", "node_list"],
  additionalProperties: false,
}