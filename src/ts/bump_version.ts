import { config } from 'dotenv'
import { statSync, writeFileSync } from 'fs'
import { join } from 'path'
import yargs from 'yargs'
import { hideBin } from 'yargs/helpers'

// .envファイルを明示的に指定して読み込む
const envPath = join(__dirname, '../.env')
const result = config({ path: envPath })

if (result.error) {
  throw new Error(`.env ファイルの読み込みに失敗しました: ${envPath}`)
}

// VERSIONが未定義の場合はエラー
if (!process.env.VERSION) {
  throw new Error('.env ファイルにVERSIONが定義されていません')
}

const version = parseInt(process.env.VERSION, 10)
if (isNaN(version) || version < 1000_00_00) {
  throw new Error('VERSIONが有効な数値ではありません')
}

interface VersionInfo {
  version: number
  size: number
}

const argv = yargs(hideBin(process.argv))
  .option('extra', {
    alias: 'e',
    type: 'boolean',
    default: false,
    description: 'エクストラフラグ'
  })
  .parseSync()

const isExtra = argv.extra
const srcPath = isExtra ? 'out/extra/json.zip' : 'out/main/json.zip'
const dstPath = isExtra ? 'latest_info.extra.json' : 'latest_info.json'

const size = statSync(srcPath).size

const info: VersionInfo = {
  version: version,
  size: size
}

writeFileSync(dstPath, JSON.stringify(info, null, 2) + '\n') 