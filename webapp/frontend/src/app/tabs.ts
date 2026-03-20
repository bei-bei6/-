export type TabId = 'topology' | 'design' | 'steady' | 'transient' | 'adaptation' | 'project'

export interface TabMeta {
  id: TabId
  label: string
  hint: string
  description: string
}

export const tabs: TabMeta[] = [
  {
    id: 'topology',
    label: '拓扑选择',
    hint: '结构',
    description: '选择本次仿真使用的燃机拓扑结构。',
  },
  {
    id: 'design',
    label: '设计点',
    hint: '设计',
    description: '配置设计点参数并查看核心计算结果。',
  },
  {
    id: 'steady',
    label: '非设计点',
    hint: '稳态',
    description: '针对不同负载工况执行稳态分析。',
  },
  {
    id: 'transient',
    label: '过渡态',
    hint: '动态',
    description: '设置控制规律并观察时序响应。',
  },
  {
    id: 'adaptation',
    label: '模型自适应',
    hint: '自适应',
    description: '预留后续模型自适应能力的扩展入口。',
  },
  {
    id: 'project',
    label: '项目文件',
    hint: '项目',
    description: '管理项目快照、结果导出与交付文件。',
  },
]

export function getTabMeta(tabId: TabId): TabMeta {
  return tabs.find((tab) => tab.id === tabId) ?? tabs[0]
}
