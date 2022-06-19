import { eachAssert, withAssert } from "./assert"

type ObjectType<Keys extends string> = {
  [key in Keys]: any
}

export function isObjectSetPartialMatched<Key extends string>(target: ObjectType<Key | "code">[], reference: Map<number, ObjectType<Key | "code">>, keys: Key[]) {
  expect(target.length).toBe(reference.size)
  const codeSet = new Set<number>()
  target.forEach(eachAssert("target", (actual, assert) => {
    assert(!codeSet.has(actual.code), "コードが重複している")
    codeSet.add(actual.code)
    const expected = reference.get(actual.code)
    assert(expected, "対応するobjectが見つからない")
    if (!expected) throw Error()
    keys.forEach(key => {
      const value = {
        actual: actual[key],
        expected: expected[key],
      }
      withAssert(`object[${key}]`, value, assert => {
        assert(JSON.stringify(value.actual) === JSON.stringify(value.expected), "Objectのプロパティが異なる")
      })
    })
  }))
}