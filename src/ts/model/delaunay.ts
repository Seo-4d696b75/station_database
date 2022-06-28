import { JSONSchemaType } from "ajv"
import { stationLineName } from "./common"
import { stationCode, stationLat, stationLng } from "./station"

export interface DelaunayStation {
  code: number
  name: string
  lat: number
  lng: number
  next: number[]
}

export const jsonDelaunayList: JSONSchemaType<DelaunayStation[]> = {
  type: "array",
  title: "隣接点リスト",
  description: "ドロネー分割による隣接点（駅座標）を各駅ごとに定義します.",
  items: {
    type: "object",
    title: "駅オブジェクト(隣接点)",
    description: "ドロネー分割による隣接点（駅座標）を定義",
    properties: {
      code: stationCode,
      name: stationLineName,
      lat: stationLat,
      lng: stationLng,
      next: {
        type: "array",
        title: "隣接駅コードリスト",
        description: "隣接駅の駅コードを要素に持ちます.",
        items: stationCode,
        minItems: 1,
        uniqueItems: true,
        examples: [
          [9910514, 1110102, 9910518, 9910622, 9910621, 9910515, 9910623, 9910517],
        ],
      }
    },
    required: [
      "code",
      "name",
      "lat",
      "lng",
      "next"
    ],
    additionalProperties: false,
  }
}