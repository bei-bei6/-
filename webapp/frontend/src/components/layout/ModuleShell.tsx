import type { ReactNode } from 'react'

import { Panel } from './Panel'

interface ModuleShellProps {
  title: string
  description: string
  eyebrow?: string
  controls: ReactNode
  results: ReactNode
}

export function ModuleShell(props: ModuleShellProps) {
  return (
    <section className="module-shell">
      <aside className="module-controls">
        <Panel title={props.title} description={props.description} eyebrow={props.eyebrow} className="module-panel">
          <div className="control-stack">{props.controls}</div>
        </Panel>
      </aside>
      <div className="module-results">
        <div className="module-results-stack">{props.results}</div>
      </div>
    </section>
  )
}
