import Ajv, { JSONSchemaType } from "ajv";
import { readFileSync } from "fs";

const ajv = new Ajv()

export function readJsonSafe<T>(path: string, schema: JSONSchemaType<T>): T {
  const str = readFileSync(path).toString()
  const validate = ajv.compile(schema)
  const data = JSON.parse(str)
  if (validate(data)) {
    return data
  }
  throw validate.errors
}

const nullValue = "NULL"
const trueValue = "1"
const falseValue = "0"

type CSVFieldType = "string" | "integer" | "number" | "boolean"

interface CSVFieldSchema {
  index: number
  name: string
  type: CSVFieldType
  nullable: boolean
}

export function readCsvSafe<T>(path: string, schema: JSONSchemaType<T>): T[] {
  if (schema.type !== "object") {
    throw Error("CSVスキーマは type:'object'が必要")
  }
  const fieldSchemaEntries = schema.properties
  if (!fieldSchemaEntries) {
    throw Error("CSVスキーマは properties: [Object] でフィールドを定義してください")
  }
  const requiredFields = schema.required
  if (!requiredFields || !Array.isArray(requiredFields)) {
    throw Error("CSVスキーマは required: string[] が必要です")
  }
  const str = readFileSync(path).toString()
  const lines = str.split(/[\r\n]+/ig)
  if (lines[lines.length - 1] === "") {
    lines.splice(lines.length - 1, 1)
  }

  // ヘッダーの確認
  const headers = lines[0].split(",")
  lines.splice(0, 1)
  const fieldSchemaList: CSVFieldSchema[] = Object.entries(fieldSchemaEntries).map(pair => {
    const [key, schema] = pair as [string, any]
    const type = schema.type
    if (typeof type !== "string") {
      throw Error(`フィールド'${key}'に型定義 type: string が見つかりません`)
    }
    if (!["string", "integer", "number", "boolean"].includes(type)) {
      throw Error(`フィールド'${key}'の型定義 type: '${type}' が不正です`)
    }
    const index = headers.findIndex(h => h === key)
    // required に設定されていないカラムの欠損を許す
    if (index < 0 && requiredFields.includes(key)) throw Error(`型定義 ${key}: ${type} に対応するCSVのヘッダーが見つかりません`)
    const nullable = !!schema.nullable
    return {
      index: index,
      name: key,
      type: type as CSVFieldType,
      nullable: nullable
    }
  })

  // 各行のバリデーション
  const validate = ajv.compile(schema)
  return lines.map((str, lineIdx) => {
    const fields = str.split(",")
    if (fields.length !== headers.length) {
      throw Error(`フィールドの数がヘッダと異なります size:${fields.length} at line ${lineIdx}: ${str}`)
    }
    const obj: any = {}
    fieldSchemaList.forEach(schema => {
      if (schema.index < 0) {
        obj[schema.name] = undefined
      } else {
        const value = parseCsvField(fields[schema.index], schema)
        obj[schema.name] = value
      }
    })
    if (validate(obj)) {
      return obj
    } else {
      throw validate.errors
    }
  })
}

function parseCsvField(value: string, schema: CSVFieldSchema): any {
  if (value === nullValue && schema.nullable) {
    return null
  }
  switch (schema.type) {
    case "string":
      return value
    case "integer":
    case "number":
      const n = Number(value)
      if (Number.isNaN(n)) {
        throw Error(`number型に変換できません：${value}`)
      }
      return n
    case "boolean":
      if (value === trueValue) {
        return true
      } else if (value === falseValue) {
        return false
      } else {
        throw Error(`boolean型に変換できません：${value}`)
      }
  }
}