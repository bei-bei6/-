import { StatsGrid } from '../../components/data-display/StatsGrid'
import { EmptyState } from '../../components/feedback/EmptyState'
import { Panel } from '../../components/layout/Panel'

export function AdaptationScreen() {
  return (
    <section className="overview-grid adaptation-grid">
      <Panel
        title="模型自适应"
        description="当前版本暂未开放自适应建模能力。"
        eyebrow="自适应"
      >
        <EmptyState
          title="暂不可用"
          text="该能力会在后续版本中开放。"
          accent="预留模块"
        />
      </Panel>

      <Panel title="功能状态" description="查看当前版本的开放情况。" eyebrow="状态">
        <StatsGrid
          items={[
            { label: '页面状态', value: '已展示' },
            { label: '计算接口', value: '未开放' },
            { label: '数据导入', value: '未开放' },
            { label: '结果导出', value: '未开放' },
          ]}
        />
      </Panel>
    </section>
  )
}
