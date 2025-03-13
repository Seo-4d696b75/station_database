export interface Assert {
  (isValid: any, errorMessage?: string): void
  equals: (actual: Primitive, expected: Primitive, errorMessage?: string) => void
}

type Primitive = string | number | boolean | null | undefined

export function withAssert<R>(where: string, value: any, testCase: (assert: Assert) => R): R {
  const assert: Assert = Object.assign(
    (isValid: any, error?: string) => {
      if (isValid === false || isValid === null || isValid === undefined) {
        const message = error ?? "assertion failed"
        throw new JestAssertionError(message, assert)
      }
    }, {
    equals: (actual: Primitive, expected: Primitive, errorMessage?: string) => {
      if (actual !== expected) {
        const message = (errorMessage ?? "assertion failed")
          + `\n\nActual:   ${actual}\nExpected: ${expected}`
        throw new JestAssertionError(message, assert.equals)
      }
    }
  }
  )
  try {
    const result = testCase(assert)
    if (result instanceof Promise) {
      return result.catch(e => {
        const dataMessage =
          "Where: " + where + "\n" +
          "Value: " + representValue(value)
        if (e instanceof JestAssertionError) {
          e.appendDataStack(dataMessage)
          return Promise.reject(e)
        } else {
          const err = new JestAssertionError("message", withAssert, e)
          err.appendDataStack(dataMessage)
          return Promise.reject(err)
        }
      }) as (R & Promise<any>)
    } else {
      return result
    }
  } catch (e) {
    const dataMessage =
      "Where: " + where + "\n" +
      "Value: " + representValue(value)
    if (e instanceof JestAssertionError) {
      e.appendDataStack(dataMessage)
      throw e
    } else {
      const err = new JestAssertionError("message", withAssert, e)
      err.appendDataStack(dataMessage)
      throw err
    }
  }
}

export function assertEach<T, R>(
  iterable: { [Symbol.iterator](): Iterator<T> },
  listName: string,
  testCase: (element: T, assert: Assert, idx: number) => R,
): R[] {
  let idx = 0
  const result: R[] = []
  for (const element of iterable) {
    result.push(withAssert(`${listName}[${idx}]`, element, assert => testCase(element, assert, idx)))
    idx++
  }
  return result
}

export async function assertEachAsync<T>(
  iterable: { [Symbol.iterator](): Iterator<T> },
  listName: string,
  testCase: (element: T, assert: Assert, idx: number) => Promise<void>,
) {
  let idx = 0
  for (const element of iterable) {
    await withAssert(`${listName}[${idx}]`, element, assert => testCase(element, assert, idx))
    idx++
  }
}

class JestAssertionError extends Error {
  message: string

  constructor(title: string, where: Function, cause?: any) {
    super(title)

    Object.defineProperty(this, 'name', {
      configurable: true,
      enumerable: false,
      value: this.constructor.name,
      writable: true,
    })


    if (cause) {
      if (cause instanceof Error) {
        this.message = `catch other error\n  ${cause.name}: ${cause.message}`
      } else {
        this.message = `something has been thrown\n${JSON.stringify(cause, undefined, 2)}`
      }
    } else {
      this.message = title
    }

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, where)
    }
  }

  appendDataStack(dataMessage: string) {
    this.message += `\n\n${dataMessage}`
  }
}

// JSON.stringifyだと長すぎるデータも簡潔に表現する
function representValue(data: any, depth: number = 2, maxItems: number = 20): string {
  if (data === null) {
    return "null"
  } else if (data === undefined) {
    return "undefined"
  } else if (Array.isArray(data)) {
    if (depth === 0) return "[Array]"
    const items = data.length > maxItems ? data.slice(0, maxItems) : data
    const itemStr = items.map(e => representValue(e, depth - 1, maxItems)).join(",")
    return data.length > maxItems ?
      `[${itemStr}, ..${data.length - maxItems} items..]` :
      `[${itemStr}]`
  } else if (typeof data === "object") {
    if (depth === 0) return "[Object]"
    const keys = Array.from(Object.keys(data))
    const select = keys.length > maxItems ? keys.splice(0, maxItems) : keys
    const itemStr = select.map(key => {
      const value = representValue(data[key], depth - 1, maxItems)
      return `"${key}":${value}`
    }).join(",")
    return data.length > maxItems ?
      `{${itemStr}, ..${data.length - maxItems} items..}` :
      `{${itemStr}}`
  } else if (typeof data === "string") {
    return `"${data}"`
  } else if (typeof data === "boolean") {
    return `${data}`
  } else if (typeof data === "number") {
    return `${data}`
  }
  throw Error("can not represent value in string:" + data)
}