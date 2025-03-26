import { JSONSchemaType } from "ajv"

function filter<T>(data: T, schema: any): T {
  if (typeof schema !== 'object' || schema === null) {
    throw new Error(`schemaがオブジェクトではありません: ${typeof schema}`)
  }

  // constが定義されている場合の処理
  if ('const' in schema) {
    if (typeof data !== 'object' || data === null) {
      // constが定義されている場合はプリミティブ値のみ検査する
      if (data !== schema.const) {
        throw new Error(`値が一致しません: ${data} !== ${schema.const}`)
      }
      return data
    } else if (typeof schema.const === 'object') {
      // TODO: object型の場合は再帰的に検証するのが難しい
      return data
    } else {
      throw new Error(`constと型が一致しません: ${typeof data} !== ${typeof schema.const}`)
    }
  }

  // プリミティブ値の場合はそのまま返す
  if (typeof data !== 'object' || data === null) {
    return data
  }

  // 配列の場合は各要素をフィルタリング
  if (Array.isArray(data)) {
    let result: unknown = filterArray(data, schema)
    return result as T
  }

  // オブジェクトの場合は各プロパティをフィルタリング
  return filterObject(data as Record<string, unknown>, schema) as T
}

function filterObject<T extends Record<string, unknown>>(data: T, schema: any): T {
  const result: Record<string, unknown> = {}
  const properties = schema.properties
  const oneOf = schema.oneOf

  if (!properties && Array.isArray(oneOf)) {
    // oneOfが定義されている場合は各スキーマを試す
    const errors: Error[] = []
    for (const subSchema of oneOf) {
      try {
        return filter(data, subSchema)
      } catch (e) {
        errors.push(e as Error)
      }
    }
    throw new Error(`oneOfのすべてのスキーマが失敗しました: ${errors.map(e => e.message).join(', ')}`)
  } else if (typeof properties === 'object') {
    // propertiesが定義されている場合は各プロパティをフィルタリング
    for (const [key, propSchema] of Object.entries(properties)) {
      if (key in data && propSchema) {
        const value = data[key]
        result[key] = filter(value, propSchema)
      }
    }
  }

  return result as T
}

function filterArray<T>(data: T[], schema: any): T[] {
  if (schema.type === 'array') {
    const items = schema.items
    if (Array.isArray(items)) {
      // データの長さがスキーマより短い場合はエラー
      if (data.length < items.length) {
        throw new Error(`配列の長さが不足しています: ${data.length} < ${items.length}`)
      }
      // 各要素をスキーマに従ってフィルタリング
      return data.slice(0, items.length).map((item, index) =>
        filter(item, items[index])
      )
    } else if (typeof items === 'object') {
      return data.map(item => filter(item, items))
    } else {
      throw new Error(`arrayの型が一致しません: ${schema.type} !== array`)
    }
  } else {
    throw new Error(`arrayの型が一致しません: ${schema.type} !== array`)
  }
}

export function filterBySchema<T>(data: T, schema: JSONSchemaType<T>): T {
  return filter(data, schema)
}