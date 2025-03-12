import Ajv, { JSONSchemaType } from "ajv";
import * as csv from "csv-parse/sync";
import { createObjectCsvWriter } from 'csv-writer';
import * as fs from "fs";
import { filterBySchema } from "./filter";
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
  const filtered = filterBySchema(data, schema)
  const str = formatJson(
    filtered,
    {
      space: 2,
      indent: (context) => !flat.includes(context.location),
      format: (context, value) => {
        // GeoJSONの座標値は整数の場合も小数点を表記する（Rubyの旧実装に合わせる）
        if (typeof value === "number" && context.location.match(/geometry\.coordinates(\[\]){2,3}$/)) {
          return Number.isInteger(value) ? value.toFixed(1) : value.toString()
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

interface CSVColumn {
  column: string
  type: CSVFieldType
  nullable: boolean
}

function toCSVColumn<T>(schema: JSONSchemaType<T>): CSVColumn[] {
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

  return Object.entries(fieldSchemaEntries).map(pair => {
    const [key, schema] = pair as [string, any]
    const type = schema.type
    if (typeof type !== "string") {
      throw Error(`フィールド'${key}'に型定義 type が見つかりません`)
    }
    if (!["string", "integer", "number", "boolean"].includes(type)) {
      throw Error(`フィールド'${key}'の型定義 type: '${type}' が不正です`)
    }
    if (!requiredFields.includes(key)) {
      throw Error(`requiredでないフィールド'${key}'を扱えません`)
    }
    const nullable = !!schema.nullable
    return {
      column: key,
      type: type as CSVFieldType,
      nullable: nullable,
      required: requiredFields.includes(key),
    }
  })
}

export function readCsvSafe<T>(path: string, schema: JSONSchemaType<T>): T[] {
  const fieldSchema = new Map(toCSVColumn(schema).map(column => [column.column, column]))

  // 値の変換
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
    for (const schema of fieldSchema.values()) {
      // ヘッダー不在の場合
      if (!header.includes(schema.column)) {
        throw Error(`ヘッダーに'${schema.column}'が見つかりません`)
      }
    }
  }

  // 各行のバリデーション
  const validateRecord = ajv.compile(schema)

  const str = fs.readFileSync(path).toString()

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


export async function writeCsvSafe<T>(path: string, schema: JSONSchemaType<T>, values: T[]) {
  const fieldSchema = toCSVColumn(schema)

  const header = fieldSchema.map(field => {
    return {
      id: field.column,
      title: field.column,
    }
  })

  const toString = (value: any, line: number, schema: CSVColumn) => {
    const { column, type, nullable } = schema
    // null確認
    if (value === null) {
      if (!nullable) {
        throw Error(`null は許可されていません column:${column} line:${line}`)
      }
      return nullValue
    }
    switch (type) {
      case "string":
        if (typeof value !== 'string') {
          throw Error(`string型で出力できません：${value} column:${column} line:${line}`)
        }
        return value
      case "integer":
        if (typeof value !== 'number') {
          throw Error(`integer型で出力できません：${value} column:${column} line:${line}`)
        }
        return Math.round(value).toString()
      case "number":
        if (typeof value !== 'number') {
          throw Error(`number型で出力できません：${value} column:${column} line:${line}`)
        }
        // 座標値は小数点以下６桁までの有効数字
        return (column === "lat" || column === "lng") ? value.toFixed(6) : value.toString()
      case "boolean":
        if (value === true) {
          return trueValue
        } else if (value === false) {
          return falseValue
        } else {
          throw Error(`boolean型に変換できません：${value} column:${column} line:${line}`)
        }
    }
  }

  const csvWriter = createObjectCsvWriter({
    path: path,
    header: header,
  })

  const records = values.map((value, index) => {
    let dst: any = {}
    for (const field of fieldSchema) {
      dst[field.column] = toString((value as any)[field.column], index + 1, field)
    }
    return dst
  })

  await csvWriter.writeRecords(records)
}