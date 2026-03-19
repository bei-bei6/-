import type { StationRow } from '../../types'
import { EmptyState } from '../feedback/EmptyState'
import { KeyTable } from './KeyTable'

interface StationTableProps {
  rows: StationRow[]
}

export function StationTable(props: StationTableProps) {
  if (!props.rows.length) {
    return <EmptyState title="没有站位表数据" text="当前结果没有返回站位表。" compact />
  }

  return <KeyTable rows={props.rows as unknown as Array<Record<string, unknown>>} />
}
