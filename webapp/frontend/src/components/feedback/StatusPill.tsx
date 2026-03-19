import clsx from 'clsx'
import type { ReactNode } from 'react'

interface StatusPillProps {
  active?: boolean
  tone?: 'neutral' | 'success' | 'warning'
  children: ReactNode
}

export function StatusPill(props: StatusPillProps) {
  return (
    <span
      className={clsx('status-pill', {
        active: props.active,
        'status-pill--warning': props.tone === 'warning',
        'status-pill--success': props.tone === 'success',
      })}
    >
      {props.children}
    </span>
  )
}
