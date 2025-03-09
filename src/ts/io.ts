import Ajv, { JSONSchemaType } from "ajv";
import * as csv from "csv-parse/sync";
import * as fs from "fs";
import { defaultPrimitiveFormatter, formatJson, JSONQuery } from "./json";
const ajv = new Ajv()

export function readJsonSafe<T>(path: string, schema: JSONSchemaType<T>): T {
  const str = fs.readFileSync(path).toString()
  const validator = ajv.compile(schema)
  const data = JSON.parse(str)
  if (validator(data)) {
    return data
  }
  throw validator.errors
}

export async function writeJsonSafe<T>(
  path: string,
  schema: JSONSchemaType<T>,
  data: T,
  flat: JSONQuery[],
) {
  const str = formatJson(
    data,
    schema,
    {
      space: 2,
      indent: (context) => !flat.includes(context.location),
      format: (context, value) => {
        if (typeof value === "number" && (context.current === "lat" || context.current === "lng")) {
          return value.toFixed(6)
        }
        return defaultPrimitiveFormatter(context, value)
      },
    },
  )
  await fs.promises.writeFile(path, str)
}

const nullValue = "NULL"
const trueValue = "1"
const falseValue = "0"

type CSVFieldType = "string" | "integer" | "number" | "boolean"

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
  const str = fs.readFileSync(path).toString()

  // 値の変換
  const fieldSchema = new Map(Object.entries(fieldSchemaEntries).map(pair => {
    const [key, schema] = pair as [string, any]
    const type = schema.type
    if (typeof type !== "string") {
      throw Error(`フィールド'${key}'に型定義 type が見つかりません`)
    }
    if (!["string", "integer", "number", "boolean"].includes(type)) {
      throw Error(`フィールド'${key}'の型定義 type: '${type}' が不正です`)
    }
    const nullable = !!schema.nullable
    return [
      key,
      {
        type: type as CSVFieldType,
        nullable: nullable
      },
    ]
  }))
  const castValue = (value: string, context: csv.CastingContext) => {
    const schema = fieldSchema.get(context.column as string)
    if (!schema) {
      // 対応するスキーマ不在の場合
      return value
    }
    const { type, nullable } = schema
    // null確認
    if (value === nullValue && !context.quoting) {
      if (!nullable) {
        throw Error(`null は許可されていません column:${context.column} line:${context.lines}`)
      }
      return null
    }
    switch (type) {
      case "string":
        return value
      case "integer":
      case "number":
        const n = Number(value)
        if (Number.isNaN(n)) {
          throw Error(`number型に変換できません：${value} column:${context.column} line:${context.lines}`)
        }
        return n
      case "boolean":
        if (value === trueValue) {
          return true
        } else if (value === falseValue) {
          return false
        } else {
          throw Error(`boolean型に変換できません：${value} column:${context.column} line:${context.lines}`)
        }
    }
  }

  // ヘッダーの確認
  const validateHeader = (header: string[]) => {
    for (const column of fieldSchema.keys()) {
      if (!header.includes(column) && requiredFields.includes(column)) {
        throw Error(`ヘッダーに'${column}'が見つかりません`)
      }
    }
  }

  // 各行のバリデーション
  const validateRecord = ajv.compile(schema)

  return csv.parse(
    str,
    {
      columns: (record) => {
        const header = record as string[]
        validateHeader(header)
        return header
      },
      cast: (value, context) => {
        if (context.header) {
          return value
        } else {
          return castValue(value, context)
        }
      },
      onRecord: (record, context) => {
        if (validateRecord(record)) {
          return record
        } else {
          throw Error(
            `validation error line:${context.lines}\n`
            + `description:\n${JSON.stringify(validateRecord.errors?.[0], undefined, 2)}\n`
            + `record:\n${JSON.stringify(record, undefined, 2)}`
          )
        }
      }
    },
  ) as T[]
}
