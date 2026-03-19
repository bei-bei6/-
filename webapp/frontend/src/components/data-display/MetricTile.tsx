import type { CSSProperties } from 'react'

interface MetricTileProps {
  label: string
  value: string
  accent: string
  detail?: string
}

export function MetricTile(props: MetricTileProps) {
  return (
    <div className="metric-tile" style={{ '--accent': props.accent } as CSSProperties}>
      <span>{props.label}</span>
      <strong>{props.value}</strong>
      {props.detail ? <small>{props.detail}</small> : null}
    </div>
  )
}
