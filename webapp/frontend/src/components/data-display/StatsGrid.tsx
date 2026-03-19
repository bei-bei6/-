import type { CSSProperties } from 'react'

const statAccents = ['#0f5b78', '#1d7f6d', '#d67a2d', '#295ea8']

interface StatsGridProps {
  items: Array<{ label: string; value: string; detail?: string }>
}

export function StatsGrid(props: StatsGridProps) {
  return (
    <div className="stats-grid">
      {props.items.map((item, index) => (
        <div
          key={item.label}
          className="stat-card"
          style={{ '--accent': statAccents[index % statAccents.length] } as CSSProperties}
        >
          <span>{item.label}</span>
          <strong>{item.value}</strong>
          {item.detail ? <small>{item.detail}</small> : null}
        </div>
      ))}
    </div>
  )
}
