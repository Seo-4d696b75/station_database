
export type Dataset = 'main' | 'extra'

export type WithExtra<D extends Dataset, T> = D extends 'main'
  ? T
  : D extends 'extra'
  ? T & { extra: boolean }
  : never

export function hasExtra<T>(value: WithExtra<Dataset, T>): value is WithExtra<'extra', T> {
  return (value as any).extra !== undefined
}

export function parseDataset(value: string | undefined | null): Dataset {
  if (value === 'main') {
    return 'main'
  }
  if (value === 'extra') {
    return 'extra'
  }
  throw new Error(`不明なデータセットの指定：${value}`)
}
