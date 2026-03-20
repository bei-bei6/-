import type { ReactNode } from 'react'

interface MastheadProps {
  title: string
  description: string
  status: ReactNode
  actions: ReactNode
}

export function Masthead(props: MastheadProps) {
  return (
    <header className="masthead">
      <div className="masthead__copy">
        <div className="hero-title-block">
          <p className="eyebrow">燃机性能仿真</p>
          <h1>{props.title}</h1>
          <p className="lead">{props.description}</p>
        </div>
      </div>
      <div className="masthead__side">
        <div className="status-cluster">{props.status}</div>
        <div className="hero-actions">{props.actions}</div>
      </div>
    </header>
  )
}
