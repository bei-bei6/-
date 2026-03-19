import clsx from 'clsx'

import type { TabId, TabMeta } from '../../app/tabs'

interface ModuleTabsProps {
  tabs: TabMeta[]
  activeTab: TabId
  onChange: (tab: TabId) => void
}

export function ModuleTabs(props: ModuleTabsProps) {
  return (
    <nav className="module-tabs" aria-label="主模块" role="tablist">
      {props.tabs.map((tab) => {
        const active = props.activeTab === tab.id
        return (
          <button
            key={tab.id}
            type="button"
            role="tab"
            aria-selected={active}
            className={clsx('module-tab', { active })}
            onClick={() => props.onChange(tab.id)}
          >
            <small>{tab.hint}</small>
            <span>{tab.label}</span>
          </button>
        )
      })}
    </nav>
  )
}
