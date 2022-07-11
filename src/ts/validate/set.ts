import { Assert, eachAssert, withAssert } from "./assert"

type ObjectType<Keys extends string> = {
  [key in Keys]: any
}

export function assertObjectSetPartialMatched<Key extends string>(target: ObjectType<Key | "code">[], reference: Map<number, ObjectType<Key | "code">>, keys: readonly Key[]) {
  expect(target.length).toBe(reference.size)
  const codeSet = new Set<number>()
  target.forEach(eachAssert("target", (actual, assert) => {
    assert(!codeSet.has(actual.code), "コードが重複している")
    codeSet.add(actual.code)
    const expected = reference.get(actual.code)
    assertObjectPartialMatched(actual, expected, keys, assert)
  }))
}

export function assertObjectPartialMatched<Key extends string>(target: ObjectType<Key | "code">, reference: ObjectType<Key | "code"> | undefined, keys: readonly Key[], assert: Assert) {
  assert(reference, "対応するobjectが見つからない")
  if (!reference) throw Error()
  keys.forEach(key => {
    const value = {
      actual: target[key],
      expected: reference[key],
    }
    withAssert(`object[${key}]`, value, assert => {
      assert(JSON.stringify(value.actual) === JSON.stringify(value.expected), "Objectのプロパティが異なる")
    })
  })
}