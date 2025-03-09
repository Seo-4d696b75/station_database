import { JSONSchemaType } from "ajv"

export type JSONQuery = string
export interface JSONFormatContext {
  /**
   * オブジェクトのパス 
   * 
   * e.g. '.station_list[].name'
   */
  readonly location: JSONQuery
  /**
   * オブジェクトの現在のパス 
   * 
   * e.g. '.station_list[].name' の場合は 'name'
   */
  readonly current: JSONQuery
  /**
   * オブジェクトの深さ
   * 
   * e.g. '.station_list[].name' の場合は 2
   */
  readonly depth: number
  readonly space: number
}
export type JSONIndentPredicate = (context: JSONFormatContext) => boolean
export type JSONPrimitive = string | number | boolean
export type JSONObject = { [key: string]: JSONValue }
export type JSONArray = JSONValue[]
export type JSONValue = JSONPrimitive | JSONObject | JSONArray | null
export type JSONPrimitiveFormatter = (context: JSONFormatContext, value: JSONPrimitive) => string

export const defaultPrimitiveFormatter: JSONPrimitiveFormatter = (context, value) => {
  if (typeof value === 'string') {
    return `"${value}"`
  }
  if (typeof value === 'number') {
    return value.toString()
  }
  if (typeof value === 'boolean') {
    return value.toString()
  }
  throw new Error(`can not format as JSONPrimitive:${JSON.stringify(value)}`)
}

const defaultIndent: JSONIndentPredicate = (context) => true

/**
 * JSON.stringifyに代わるカスタムエンコーダー
 * 
 * @param data 文字列に変換するオブジェクト
 * @param options オプション
 * @param options.indent `true`の場合インデントする. デフォルトではすべての場合にインデントする.
 * @param options.format プリミティブ値のフォーマットを指定する関数
 * @param options.space インデントのスペース数
 * 
 * @see defaultPrimitiveFormatter
 */
export function formatJson<T>(
  data: T,
  schema: JSONSchemaType<T>,
  options: {
    indent?: JSONIndentPredicate,
    format?: JSONPrimitiveFormatter,
    space?: number,
  } = {},
): string {
  const context: JSONFormatContext = {
    location: '.',
    current: '.',
    depth: 0,
    space: options.space ?? 2,
  }
  const result = formatJsonValue(
    context,
    data,
    schema,
    options.format ?? defaultPrimitiveFormatter,
    options.indent ?? defaultIndent,
  )
  return result
}

function formatJsonValue(
  context: JSONFormatContext,
  value: any,
  schema: any,
  format: JSONPrimitiveFormatter,
  indent?: JSONIndentPredicate,
): string {
  if (value === null) {
    if (!schema.nullable) {
      throw new Error(`null not allowed at ${context.location}`)
    }
    return 'null'
  }
  if (typeof value === 'string') {
    if (schema.type !== 'string') {
      throw new Error(`string not allowed at ${context.location}`)
    }
    return format(context, value)
  }
  if (typeof value === 'number') {
    if (schema.type !== 'number' && schema.type !== 'integer') {
      throw new Error(`number not allowed at ${context.location}`)
    }
    return value.toString()
  }
  if (typeof value === 'boolean') {
    if (schema.type !== 'boolean') {
      throw new Error(`boolean not allowed at ${context.location}`)
    }
    return value.toString()
  }
  if (Array.isArray(value)) {
    if (schema.type !== 'array') {
      throw new Error(`array not allowed at ${context.location}`)
    }
    return formatJsonArray(
      context,
      value,
      schema,
      format,
      indent,
    )
  }
  if (value && typeof value === 'object') {
    if (schema.type !== 'object') {
      throw new Error(`object not allowed at ${context.location}`)
    }
    return formatJsonObject(
      context,
      value,
      schema,
      format,
      indent,
    )
  }
  throw new Error(`can not format as JSONValue:${JSON.stringify(value)}`)
}

function formatJsonArray(
  context: JSONFormatContext,
  array: JSONArray,
  schema: any,
  format: JSONPrimitiveFormatter,
  indent?: JSONIndentPredicate,
): string {
  let str = '['
  const shouldIndent = indent && indent(context)
  if (shouldIndent) {
    str += '\n' + ' '.repeat(context.space * (context.depth + 1))
  }
  const sep = shouldIndent ? ',\n' + ' '.repeat(context.space * (context.depth + 1)) : ','
  const elementContext: JSONFormatContext = {
    location: context.location + '[]',
    current: context.current + '[]',
    depth: context.depth + 1,
    space: context.space,
  }
  const elementSchema = schema.items
  if (typeof elementSchema !== 'object') {
    throw new Error(`JSONSchema of array element not found at ${elementContext.location}`)
  }
  const elements = array.map(value =>
    formatJsonValue(
      elementContext,
      value,
      elementSchema,
      format,
      shouldIndent ? indent : undefined,
    )
  )

  str += elements.join(sep)
  if (shouldIndent) {
    str += '\n' + ' '.repeat(context.space * context.depth)
  }
  str += ']'
  return str
}

function formatJsonObject(
  context: JSONFormatContext,
  obj: JSONObject,
  schema: any,
  format: JSONPrimitiveFormatter,
  indent?: JSONIndentPredicate,
): string {
  const properties = schema.properties
  if (typeof properties !== 'object') {
    throw new Error(`'properties' of JSONSchema not found at ${context.location}`)
  }
  const required = schema.required
  if (required && !Array.isArray(required)) {
    throw new Error(`invalid 'required' of JSONSchema at ${context.location}`)
  }

  let str = '{'
  const shouldIndent = indent && indent(context)
  if (shouldIndent) {
    str += '\n' + ' '.repeat(context.space * (context.depth + 1))
  }

  const sep = shouldIndent ? ',\n' + ' '.repeat(context.space * (context.depth + 1)) : ','

  const entries = Object.entries(properties).map(([key, entrySchema]) => {
    const value = obj[key]
    if (value === undefined) {
      if (required && required.includes(key)) {
        throw new Error(`required property is undefined at ${context.location + key}`)
      }
      return undefined
    }
    const formattedValue = formatJsonValue(
      {
        location: context.location + key,
        current: key,
        depth: context.depth + 1,
        space: context.space,
      },
      value,
      entrySchema,
      format,
      shouldIndent ? indent : undefined,
    )
    return `"${key}":${formattedValue}`
  }).filter(entry => entry !== undefined)

  str += entries.join(sep)
  if (shouldIndent) {
    str += '\n' + ' '.repeat(context.space * context.depth)
  }
  str += '}'
  return str
}
