import clsx from 'clsx'

interface EmptyStateProps {
  title: string
  text: string
  compact?: boolean
  accent?: string
}

export function EmptyState(props: EmptyStateProps) {
  return (
    <div className={clsx('empty-state', { compact: props.compact })}>
      {props.accent ? <span className="empty-state__accent">{props.accent}</span> : null}
      <strong>{props.title}</strong>
      <p>{props.text}</p>
    </div>
  )
}
