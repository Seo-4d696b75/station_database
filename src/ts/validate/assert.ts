export type Assert = (isValid: any, errorMessage?: string) => void

export function withAssert<R = void>(where: string, value: any, testCase: (assert: Assert) => R): R {
  const assert: Assert = (isValid, error) => {
    if (isValid === false || isValid === null || isValid === undefined) {
      const message = error ?? "assertion failed"
      throw new JestAssertionError(message, assert)
    }
  }
  try {
    return testCase(assert)
  } catch (e) {
    if (e instanceof JestAssertionError) {
      const dataMessage =
        "Where: " + where + "\n" +
        "Value: " + JSON.stringify(value)
      e.data = [dataMessage, ...e.data]
      e.message = e.title + "\n\n" + e.data.join("\n\n")
    }
    throw e
  }
}

export function eachAssert<T, R = void>(listName: string, testCase: (element: T, assert: Assert, idx: number) => R): ((element: T, idx: number) => R) {
  return (element, idx) => withAssert(`${listName}[${idx}]`, element, assert => testCase(element, assert, idx))
}

class JestAssertionError extends Error {
  data: string[]
  title: string
  message: string

  constructor(title: string, where: Function) {
    super(title)
    this.data = []
    this.title = title
    this.message = title

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, where)
    }
  }
}