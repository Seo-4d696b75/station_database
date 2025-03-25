import { parse } from 'dotenv'
import { readFile } from 'fs/promises'
import * as crypto from 'crypto'

test('バージョン更新の確認', async () => {
  const oldEnv = parse(await readFile('artifact/.env'))
  const newEnv = parse(await readFile('src/.env'))

  const oldVersion = parseInt(oldEnv.VERSION || '0', 10)
  if (!oldVersion || oldVersion < 1000_00_00) {
    throw new Error('旧バージョンが不明です')
  }

  const newVersion = parseInt(newEnv.VERSION || '0', 10)
  if (!newVersion || newVersion < 1000_00_00) {
    throw new Error('新バージョンが不明です')
  }

  const oldMainHash = await md5('artifact/main.zip')
  const oldExtraHash = await md5('artifact/extra.zip')
  const newMainHash = await md5('out/main/json.zip')
  const newExtraHash = await md5('out/extra/json.zip')
  if (oldMainHash === newMainHash && oldExtraHash === newExtraHash) {
    expect(newVersion).toBe(oldVersion)
    console.log(`バージョン ${oldVersion} (データ変更なし)`)
  } else {
    expect(newVersion).toBeGreaterThan(oldVersion)
    console.log(`バージョン ${oldVersion} > ${newVersion}`)
  }
})

async function md5(path: string): Promise<string> {
  const md5 = crypto.createHash('md5')
  const bin = await readFile(path)
  return md5.update(bin).digest('hex')
}