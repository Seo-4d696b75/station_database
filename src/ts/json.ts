
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
export type JSONValue = JSONPrimitive | JSONObject | JSONArray | null | undefined
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
  options: {
    indent?: JSONIndentPredicate,
    format?: JSONPrimitiveFormatter,
    space?: number,
  } = {},
): string {
  const context: JSONFormatContext = {
    location: '',
    current: '',
    depth: 0,
    space: options.space ?? 2,
  }
  const result = formatJsonValue(
    context,
    data,
    options.format ?? defaultPrimitiveFormatter,
    options.indent ?? defaultIndent,
  )
  return result
}

class JSONFormatError extends Error {
  constructor(context: JSONFormatContext, message: string) {
    super(`${context.location}: ${message}`)
  }
}

function formatJsonValue(
  context: JSONFormatContext,
  value: any,
  format: JSONPrimitiveFormatter,
  indent: JSONIndentPredicate | null,
): string {
  if (value === null) {
    return 'null'
  }
  if (typeof value === 'string') {
    return format(context, value)
  }
  if (typeof value === 'number') {
    return format(context, value)
  }
  if (typeof value === 'boolean') {
    return format(context, value)
  }
  if (Array.isArray(value)) {
    return formatJsonArray(
      context,
      value,
      format,
      indent,
    )
  }
  if (value && typeof value === 'object') {
    return formatJsonObject(
      context,
      value,
      format,
      indent,
    )
  }
  throw new JSONFormatError(context, `can not format as JSONValue:${JSON.stringify(value)}`)
}

function formatJsonArray(
  context: JSONFormatContext,
  array: JSONArray,
  format: JSONPrimitiveFormatter,
  indent: JSONIndentPredicate | null,
): string {
  let str = '['
  const shouldIndent = indent && indent(context)
  if (shouldIndent) {
    str += '\n' + ' '.repeat(context.space * (context.depth + 1))
  }
  const sep = shouldIndent ? ',\n' + ' '.repeat(context.space * (context.depth + 1)) : ','
  const elementContext: JSONFormatContext = {
    location: context.location === '' ? '.[]' : context.location + '[]',
    current: context.current === '' ? '.[]' : context.current + '[]',
    depth: context.depth + 1,
    space: context.space,

  }
  const elements = array
    .filter(value => value !== undefined)
    .map(value => formatJsonValue(
      elementContext,
      value,
      format,
      shouldIndent ? indent : null,
    ))

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
  format: JSONPrimitiveFormatter,
  indent: JSONIndentPredicate | null,
): string {
  let str = '{'
  const shouldIndent = indent && indent(context)
  if (shouldIndent) {
    str += '\n' + ' '.repeat(context.space * (context.depth + 1))
  }

  const sep = shouldIndent ? ',\n' + ' '.repeat(context.space * (context.depth + 1)) : ','

  const entries = Object
    .entries(obj)
    .filter(([_, value]) => value !== undefined)
    .map(([key, value]) => {
      const elementContext: JSONFormatContext = {
        location: context.location + '.' + key,
        current: key,
        depth: context.depth + 1,
        space: context.space,
      }
      const formattedValue = formatJsonValue(
        elementContext,
        value,
        format,
        shouldIndent ? indent : null,
      )
      return `"${key}":${formattedValue}`
    })

  str += entries.join(sep)
  if (shouldIndent) {
    str += '\n' + ' '.repeat(context.space * context.depth)
  }
  str += '}'
  return str
}
