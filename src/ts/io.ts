import Ajv, { JSONSchemaType } from "ajv";
import { readFileSync } from "fs"

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
    throw Error("CSVスキーマは required: string[] が必要")
  }
  const str = readFileSync(path).toString()
  const lines = str.split(/[\r\n]+/ig)
  if (lines[lines.length - 1] === "") {
    lines.splice(lines.length - 1, 1)
  }
  const headers = lines[0].split(",")
  lines.splice(0, 1)
  const fieldSchemaList: CSVFieldSchema[] = headers.map(header => {
    const schema = fieldSchemaEntries[header]
    if (!schema) {
      throw Error(`フィールド'${header}'に該当するスキーマが見つかりません`)
    }
    const type = schema.type
    if (typeof type !== "string") {
      throw Error(`フィールド'${header}'に型定義 type: string が見つかりません`)
    }
    if (!["string", "integer", "number", "boolean"].includes(type)) {
      throw Error(`フィールド'${header}'の型定義 type: '${type}' が不正です`)
    }
    const nullable = !!schema.nullable
    return {
      name: header,
      type: type as CSVFieldType,
      nullable: nullable
    }
  })
  // 欠損・順序の確認
  let previousIdx = -1
  let previousKey = ""
  for (const [key, fieldSchema] of Object.entries(fieldSchemaEntries)) {
    const idx = headers.findIndex(f => f === key)
    if (idx < 0) {
      if (requiredFields.includes(key)) {
        throw Error(`requiredに指定されたフィールド'${key}'が見つかりません`)
      }
    } else {
      if (previousIdx > idx) {
        throw Error(`フィールド'${key}'と'${previousKey}'の順序がスキーマと反転しています`)
      }
      previousIdx = idx
      previousKey = key
    }
  }
  // 各行のバリデーション
  const validate = ajv.compile(schema)
  return lines.map((str,lineIdx) => {
    const fields = str.split(",")
    if (fields.length !== fieldSchemaList.length) {
      throw Error(`フィールドの数がヘッダと異なります size:${fields.length} at line ${lineIdx}: ${str}`)
    }
    const obj: any = {}
    fields.forEach((v, i) => {
      const schema = fieldSchemaList[i]
      const value = parseCsvField(v, schema)
      obj[schema.name] = value
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