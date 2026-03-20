import { formatNumber } from '../../utils'

export const baseChartMargin = { top: 12, right: 44, bottom: 12, left: 18 }
export const axisTickStyle = { fontSize: 12, fill: '#5b6f80' }
export const axisLineStyle = { stroke: '#c7d3dd' }

export function formatChartAxisValue(value: unknown): string {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value.toLocaleString('zh-CN', {
      notation: 'compact',
      compactDisplay: 'short',
      maximumFractionDigits: 2,
    })
  }

  if (typeof value === 'string' && value.trim()) {
    const parsed = Number(value)
    if (Number.isFinite(parsed)) {
      return parsed.toLocaleString('zh-CN', {
        notation: 'compact',
        compactDisplay: 'short',
        maximumFractionDigits: 2,
      })
    }
    return value
  }

  return '-'
}

export function formatChartTooltipValue(value: unknown): string {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return formatNumber(value, 4)
  }

  if (typeof value === 'string' && value.trim()) {
    return value
  }

  return '-'
}
