import type { ReactNode } from 'react'

interface CommandDeckProps {
  title: string
  description: string
  contextTags: string[]
  actions: ReactNode
  metrics: ReactNode
}

export function CommandDeck(props: CommandDeckProps) {
  return (
    <section className="command-deck">
      <div className="command-card command-card--hero">
        <div className="command-card__copy">
          <p className="eyebrow">当前项目</p>
          <h2>{props.title}</h2>
          <p className="deck-copy">{props.description}</p>
          <div className="tag-row">
            {props.contextTags.map((tag) => (
              <span key={tag} className="tag tag--muted">
                {tag}
              </span>
            ))}
          </div>
        </div>
        <div className="command-buttons">{props.actions}</div>
      </div>
      <div className="command-summary-grid">{props.metrics}</div>
    </section>
  )
}
