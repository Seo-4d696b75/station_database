export type Assert = (isValid: any, errorMessage?: string) => void

export function getAssert(where: string, value?: any): Assert {
  return (isValid, error) => {
    if (isValid === false || isValid === null || isValid === undefined) {
      throw Error([
        error ?? "assertion failed",
        "at " + where,
        "value: " + JSON.stringify(value),
      ].join("\n"))
    }
  }
}