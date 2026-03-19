import type { AnyRecord } from '../../types'
import { formatNumber } from '../../utils'
import { Panel } from '../layout/Panel'

interface ObjectCardsProps {
  title: string
  data: Record<string, AnyRecord>
}

export function ObjectCards(props: ObjectCardsProps) {
  return (
    <Panel title={props.title} description="汇总展示各部件性能指标与求解输出。">
      <div className="object-grid">
        {Object.entries(props.data).map(([name, value]) => (
          <div key={name} className="object-card">
            <h4>{name}</h4>
            <div className="object-list">
              {flattenRecord(value).map(([key, item]) => (
                <div key={`${name}-${key}`} className="object-row">
                  <span>{key}</span>
                  <strong>{formatComponentValue(item)}</strong>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Panel>
  )
}

function flattenRecord(source: AnyRecord, prefix = ''): Array<[string, unknown]> {
  return Object.entries(source).flatMap(([key, value]) => {
    const nextKey = prefix ? `${prefix}.${key}` : key
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return flattenRecord(value as AnyRecord, nextKey)
    }
    return [[nextKey, value]]
  })
}

function formatComponentValue(value: unknown): string {
  if (Array.isArray(value)) return value.join(', ')
  if (typeof value === 'number') return formatNumber(value, 4)
  if (typeof value === 'boolean') return value ? 'true' : 'false'
  if (value === null || value === undefined) return '-'
  return String(value)
}
