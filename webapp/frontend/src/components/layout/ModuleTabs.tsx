import clsx from 'clsx'

import type { TabId, TabMeta } from '../../app/tabs'

interface ModuleTabsProps {
  tabs: TabMeta[]
  activeTab: TabId
  onChange: (tab: TabId) => void
}

export function ModuleTabs(props: ModuleTabsProps) {
  return (
    <nav className="module-tabs" aria-label={'\u4e3b\u6a21\u5757'} role="tablist">
      {props.tabs.map((tab, index) => {
        const active = props.activeTab === tab.id
        return (
          <button
            key={tab.id}
            type="button"
            role="tab"
            aria-selected={active}
            className={clsx('module-tab', { active })}
            onClick={() => props.onChange(tab.id)}
            title={tab.description}
          >
            <div className="module-tab__meta">
              <small>{tab.hint}</small>
              <span className="module-tab__index">{String(index + 1).padStart(2, '0')}</span>
            </div>
            <span className="module-tab__label">{tab.label}</span>
            <p className="module-tab__description">{tab.description}</p>
          </button>
        )
      })}
    </nav>
  )
}
