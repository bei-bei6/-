import { StatsGrid } from '../../components/data-display/StatsGrid'
import { EmptyState } from '../../components/feedback/EmptyState'
import { Panel } from '../../components/layout/Panel'

export function AdaptationScreen() {
  return (
    <section className="overview-grid adaptation-grid">
      <Panel
        title="模型自适应"
        description="当前版本暂不开放该功能。"
        eyebrow="自适应"
      >
        <EmptyState
          title="暂不可用"
          text="该功能将在后续版本开放。"
          accent="暂停开放"
        />
      </Panel>

      <Panel title="功能状态" description="查看当前版本的开放情况。" eyebrow="状态">
        <StatsGrid
          items={[
            { label: '页面状态', value: '已显示' },
            { label: '计算接口', value: '未开放' },
            { label: '数据导入', value: '未开放' },
            { label: '结果输出', value: '未开放' },
          ]}
        />
      </Panel>
    </section>
  )
}
