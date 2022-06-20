export interface Assert {
  (isValid: any, errorMessage?: string): void
  equals: (actual: Primitive, expected: Primitive, errorMessage?: string) => void
}

type Primitive = string | number | boolean | null | undefined

export function withAssert<R = void>(where: string, value: any, testCase: (assert: Assert) => R): R {
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
    return testCase(assert)
  } catch (e) {
    const dataMessage =
      "Where: " + where + "\n" +
      "Value: " + JSON.stringify(value)
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

export function eachAssert<T, R = void>(listName: string, testCase: (element: T, assert: Assert, idx: number) => R): ((element: T, idx: number) => R) {
  return (element, idx) => withAssert(`${listName}[${idx}]`, element, assert => testCase(element, assert, idx))
}

class JestAssertionError extends Error {
  data: string[]
  title: string
  message: string
  stackTrace: string = ""

  constructor(title: string, where: Function, cause?: any) {
    super(title)

    Object.defineProperty(this, 'name', {
      configurable: true,
      enumerable: false,
      value: this.constructor.name,
      writable: true,
    })

    this.data = []
    this.title = title

    if (cause) {
      if (cause instanceof Error) {
        this.title = `catch other error\n  ${cause.name}: ${cause.message}`
      } else {
        this.title = `something has been thrown\n${JSON.stringify(cause, undefined, 2)}`
      }
    }

    this.message = this.title

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, where)
      this.stackTrace = extractStackTrace(this)
      if (cause instanceof Error && cause.stack) {
        this.stackTrace = extractStackTrace(cause)
          + "\n\nJestAssertionError is thrown from\n"
          + this.stackTrace
        this.stack = "JestAssertionError: "
          + this.message
          + "\n\n"
          + this.stackTrace
      }
    }
  }

  appendDataStack(dataMessage: string) {
    this.data = [dataMessage, ...this.data]
    this.message = this.title + "\n\n" + this.data.join("\n\n")
    this.stack = "JestAssertionError: "
      + this.message
      + "\n\n"
      + this.stackTrace
  }
}

function extractStackTrace(e: Error): string {
  const str = e.stack
  if (!str) return ""
  const m = str.match(/(?<trace>(at\s+.+[\n\r\s]*)+)$/)
  if (!m) return ""
  return m.groups?.["trace"] ?? ""
}