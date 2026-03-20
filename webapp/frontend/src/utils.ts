import type { AnyRecord, ChartSeries } from './types'

export function deepClone<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T
}

export function getByPath(source: AnyRecord, path: string): unknown {
  const segments = path.split('.')
  let current: unknown = source
  for (const segment of segments) {
    if (current === null || typeof current !== 'object' || !(segment in current)) {
      return undefined
    }
    current = (current as AnyRecord)[segment]
  }
  return current
}

export function setByPath<T extends AnyRecord>(source: T, path: string, value: unknown): T {
  const clone = deepClone(source)
  const segments = path.split('.')
  let current: AnyRecord = clone

  for (let index = 0; index < segments.length - 1; index += 1) {
    const segment = segments[index]
    const next = current[segment]
    if (next === null || typeof next !== 'object' || Array.isArray(next)) {
      current[segment] = {}
    }
    current = current[segment] as AnyRecord
  }

  current[segments[segments.length - 1]] = value
  return clone
}

export function formatNumber(value: unknown, digits = 3): string {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value.toLocaleString('zh-CN', {
      maximumFractionDigits: digits,
      minimumFractionDigits: digits > 0 ? 0 : 0,
    })
  }
  if (typeof value === 'string' && value.trim()) {
    return value
  }
  return '-'
}

export function numberValue(value: unknown, fallback = 0): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value
  }
  if (typeof value === 'string') {
    const parsed = Number(value)
    if (Number.isFinite(parsed)) {
      return parsed
    }
  }
  return fallback
}

export function parseNumericList(text: string): number[] {
  return text
    .split(/[\s,;]+/)
    .map((item) => item.trim())
    .filter(Boolean)
    .map((item) => Number(item))
    .filter((item) => Number.isFinite(item))
}

export function listToText(value: unknown): string {
  if (!Array.isArray(value)) {
    return ''
  }
  return value
    .map((item) => (typeof item === 'number' ? item.toString() : String(item)))
    .join(', ')
}

export function rowsToCsv(rows: Array<Record<string, unknown>>): string {
  if (!rows.length) {
    return ''
  }

  const headers = Array.from(
    rows.reduce((keys, row) => {
      Object.keys(row).forEach((key) => keys.add(key))
      return keys
    }, new Set<string>()),
  )

  const encode = (value: unknown): string => {
    if (value === null || value === undefined) {
      return ''
    }
    const raw =
      typeof value === 'object'
        ? JSON.stringify(value)
        : typeof value === 'number'
          ? value.toString()
          : String(value)
    return `"${raw.replaceAll('"', '""')}"`
  }

  const lines = [
    headers.join(','),
    ...rows.map((row) => headers.map((header) => encode(row[header])).join(',')),
  ]
  return lines.join('\n')
}

export function downloadText(filename: string, content: string, mimeType: string): void {
  const blob = new Blob([content], { type: mimeType })
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  anchor.click()
  URL.revokeObjectURL(url)
}

export function downloadJson(filename: string, value: unknown): void {
  downloadText(filename, JSON.stringify(value, null, 2), 'application/json;charset=utf-8')
}

export async function readTextFile(file: File): Promise<string> {
  return file.text()
}

export function parseScheduleCsv(
  text: string,
  valueKey: 'Loading' | 'Rout' = 'Loading',
): { time: number[]; [key: string]: number[] } {
  const lines = text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)

  if (!lines.length) {
    return { time: [], [valueKey]: [] }
  }

  const splitLine = (line: string): string[] => line.split(/[,\t;]+/).map((item) => item.trim())
  const firstRow = splitLine(lines[0])
  const hasHeader = firstRow.some((cell) => Number.isNaN(Number(cell)))
  const dataLines = hasHeader ? lines.slice(1) : lines

  const rows = dataLines
    .map(splitLine)
    .filter((cells) => cells.length >= 2)
    .map((cells) => ({
      time: Number(cells[0]),
      value: Number(cells[1]),
    }))
    .filter((row) => Number.isFinite(row.time) && Number.isFinite(row.value))

  return {
    time: rows.map((row) => row.time),
    [valueKey]: rows.map((row) => row.value),
  }
}

export function buildMergedChartRows(seriesList: ChartSeries[]): Array<Record<string, number>> {
  const rows = new Map<number, Record<string, number>>()

  seriesList.forEach((series) => {
    series.points.forEach((point) => {
      const key = Number(point.time.toFixed(6))
      const row = rows.get(key) ?? { time: point.time }
      row[series.name] = point.value
      rows.set(key, row)
    })
  })

  return Array.from(rows.values()).sort((left, right) => left.time - right.time)
}

function buildSampleIndexes(length: number, maxPoints: number): number[] {
  if (length <= maxPoints) {
    return Array.from({ length }, (_, index) => index)
  }

  const indexes = new Set<number>([0, length - 1])
  const step = (length - 1) / (maxPoints - 1)

  for (let index = 1; index < maxPoints - 1; index += 1) {
    indexes.add(Math.round(index * step))
  }

  return Array.from(indexes).sort((left, right) => left - right)
}

export function downsampleRows<T>(rows: T[], maxPoints = 180): T[] {
  if (rows.length <= maxPoints || maxPoints < 3) {
    return rows
  }

  return buildSampleIndexes(rows.length, maxPoints).map((index) => rows[index])
}
