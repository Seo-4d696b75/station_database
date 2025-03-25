import { parse } from 'dotenv'
import { readFileSync } from 'fs'

test('バージョン更新の確認', () => {
  const oldEnv = parse(readFileSync('artifact/.env'))
  const newEnv = parse(readFileSync('src/.env'))

  const oldVersion = parseInt(oldEnv.VERSION || '0', 10)
  if (!oldVersion || oldVersion < 1000_00_00) {
    throw new Error('旧バージョンが不明です')
  }

  const newVersion = parseInt(newEnv.VERSION || '0', 10)
  if (!newVersion || newVersion < 1000_00_00) {
    throw new Error('新バージョンが不明です')
  }

  expect(newVersion).toBeGreaterThan(oldVersion)
  console.log(`バージョン ${oldVersion} > ${newVersion}`)
})
