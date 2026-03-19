import { formatNumber } from '../../utils'
import { EmptyState } from '../feedback/EmptyState'

interface KeyTableProps {
  rows: Array<Record<string, unknown>>
}

export function KeyTable(props: KeyTableProps) {
  if (!props.rows.length) {
    return <EmptyState title="没有可显示的数据" text="当前区域没有返回表格数据。" compact />
  }

  const headers = Object.keys(props.rows[0])

  return (
    <div className="table-wrap">
      <table className="data-table">
        <thead>
          <tr>
            {headers.map((header) => (
              <th key={header}>{formatHeader(header)}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {props.rows.map((row, index) => (
            <tr key={index}>
              {headers.map((header) => {
                const value = row[header]
                const numeric = isNumericValue(value)
                return (
                  <td key={header} className={numeric ? 'cell-number' : 'cell-text'} title={formatCellValue(value)}>
                    {formatCellValue(value)}
                  </td>
                )
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function isNumericValue(value: unknown): boolean {
  if (typeof value === 'number') return Number.isFinite(value)
  if (typeof value === 'string' && value.trim()) return Number.isFinite(Number(value))
  return false
}

function formatCellValue(value: unknown): string {
  if (Array.isArray(value)) {
    return value.map((item) => formatCellValue(item)).join(', ')
  }

  if (value && typeof value === 'object') {
    return JSON.stringify(value)
  }

  return formatNumber(value, 4)
}

function formatHeader(header: string): string {
  return header.replaceAll('_', ' ')
}
