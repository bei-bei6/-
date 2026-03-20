import type { ReactNode } from 'react'

import type { TabId, TabMeta } from './tabs'
import { ModuleTabs } from '../components/layout/ModuleTabs'
import { Masthead } from '../components/layout/Masthead'
import { CommandDeck } from '../components/layout/CommandDeck'
import { AlertBanner } from '../components/feedback/AlertBanner'

interface AppShellProps {
  title: string
  description: string
  status: ReactNode
  mastheadActions: ReactNode
  commandTitle: string
  commandDescription: string
  contextTags: string[]
  commandActions: ReactNode
  metrics: ReactNode
  tabs: TabMeta[]
  activeTab: TabId
  onTabChange: (tab: TabId) => void
  busyMessage?: string
  errorMessage?: string
  children: ReactNode
}

export function AppShell(props: AppShellProps) {
  return (
    <div className="app-shell">
      <Masthead
        title={props.title}
        description={props.description}
        status={props.status}
        actions={props.mastheadActions}
      />

      <CommandDeck
        title={props.commandTitle}
        description={props.commandDescription}
        contextTags={props.contextTags}
        actions={props.commandActions}
        metrics={props.metrics}
      />

      <div className="app-topnav">
        <div className="app-topnav__section">
          <p className="eyebrow">模块导航</p>
          <ModuleTabs tabs={props.tabs} activeTab={props.activeTab} onChange={props.onTabChange} />
        </div>
      </div>

      {props.busyMessage ? <AlertBanner tone="info" message={props.busyMessage} /> : null}
      {props.errorMessage ? <AlertBanner tone="error" message={props.errorMessage} /> : null}

      <main className="app-main">{props.children}</main>
    </div>
  )
}
