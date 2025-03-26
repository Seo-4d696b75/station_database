import { JSONSchemaType } from "ajv"

export const stationLineId: JSONSchemaType<string> = {
  type: "string",
  pattern: "^[0-9a-f]{6}$",
  title: "駅・路線ID",
  description: "データセット内の駅と路線を一意に区別する値. 駅コードや路線コードとは異なり、別バージョンのデータセット間でも一貫性を保証します（駅メモ実装における「同じ」駅・路線のIDは異なるデータセットでも同じIDになります）.",
  examples: [
    "d8aab0",
    "e16e64",
  ],
}

export const stationLineName: JSONSchemaType<string> = {
  type: "string",
  minLength: 1,
  title: "駅・路線の名前",
  description: "駅メモに実装されているのと同じ名称です. データセット内で重複はありません. 重複防止の接尾語が付加される場合があります.",
  examples: [
    "函館",
    "福島(福島)",
    "JR函館本線(函館～長万部)",
  ],
}

export const originalStationName: JSONSchemaType<string> = {
  type: "string",
  minLength: 1,
  title: "オリジナルの駅名称",
  description: "原則として各鉄道会社が示すままの駅名と同じ値です. nameとは異なり重複防止の接尾語を含みません.",
  examples: [
    "函館", "福島"
  ]
}

export const kanaName: JSONSchemaType<string> = {
  type: "string",
  pattern: "^[\\p{sc=Hiragana}ー・\\p{gc=P}\\s]+$",
  title: "駅・路線の名前のかな表現",
  description: "駅メモに実装されているのと同じ名称です. ひらがな以外に一部記号を含む場合があります.",
  examples: [
    "はこだて",
    "ふくしま",
    "じぇいあーるはこだてほんせん",
  ]
}

export const stationAttr: JSONSchemaType<string> = {
  type: "string",
  title: "駅の属性",
  description: "駅メモで定義された各駅の属性値. 廃駅の場合は'unknown'.",
  enum: [
    "eco",
    "heat",
    "cool",
    "unknown",
  ]
}

export const dateStringPattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"

export const stationLineExtra = {
  type: "boolean" as const,
  title: "駅・路線が独自実装の登録か否かを表します",
  description: "false: 駅メモに登録されています. true: 独自追加された廃駅・廃線です(extraデータセットのみ).",
}