import clsx from 'clsx'
import type { ReactNode } from 'react'

interface PanelProps {
  title: string
  description?: string
  eyebrow?: string
  actions?: ReactNode
  className?: string
  children: ReactNode
}

export function Panel(props: PanelProps) {
  return (
    <section className={clsx('panel', props.className)}>
      <div className="panel-header">
        <div className="panel-header__copy">
          {props.eyebrow ? <p className="eyebrow">{props.eyebrow}</p> : null}
          <h3>{props.title}</h3>
          {props.description ? <p>{props.description}</p> : null}
        </div>
        {props.actions ? <div className="panel-header__actions">{props.actions}</div> : null}
      </div>
      {props.children}
    </section>
  )
}
