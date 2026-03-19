import clsx from 'clsx'

import type { Topology } from '../../types'
import { Panel } from '../../components/layout/Panel'
import { StatusPill } from '../../components/feedback/StatusPill'
import { StatsGrid } from '../../components/data-display/StatsGrid'

interface TopologyScreenProps {
  topologies: Topology[]
  selectedTopology: string
  onSelect: (topologyId: string) => void
  runtimeInstalled: boolean
  designReady: boolean
  steadyReady: boolean
  transientReady: boolean
}

export function TopologyScreen(props: TopologyScreenProps) {
  const selectedTopologyMeta = props.topologies.find((item) => item.id === props.selectedTopology) ?? null
  const availableCount = props.topologies.filter((item) => item.available).length

  return (
    <section className="overview-grid topology-grid">
      <Panel
        title="燃机结构选型"
        description="选择当前可用于计算的燃机结构。"
        eyebrow="结构"
      >
        <div className="topology-hero">
          <div>
            <h4>{selectedTopologyMeta?.name ?? '未选择拓扑'}</h4>
            <p>{selectedTopologyMeta?.description ?? '请选择一个可用拓扑后继续。'}</p>
          </div>
          <div className="tag-row">
            <span className="tag">可用拓扑 {availableCount}</span>
            <span className="tag">当前选择</span>
          </div>
        </div>

        <div className="topology-gallery">
          {props.topologies.map((topology) => {
            const active = props.selectedTopology === topology.id
            return (
              <button
                key={topology.id}
                type="button"
                className={clsx('topology-card', {
                  active,
                  unavailable: !topology.available,
                })}
                onClick={() => topology.available && props.onSelect(topology.id)}
                disabled={!topology.available}
              >
                <div className="topology-card__head">
                  <div>
                    <h3>{topology.name}</h3>
                    <p>{topology.description}</p>
                  </div>
                  <StatusPill active={topology.available} tone={topology.available ? 'success' : 'warning'}>
                    {topology.available ? (active ? '当前选择' : '可选择') : '不可用'}
                  </StatusPill>
                </div>
              </button>
            )
          })}
        </div>
      </Panel>

      <Panel
        title="运行状态"
        description="查看当前结构、运行环境和结果状态。"
        eyebrow="状态"
      >
        <div className="capability-list">
          <div className="capability-item">
            <strong>当前拓扑</strong>
            <span>{selectedTopologyMeta?.name ?? '-'}</span>
          </div>
          <div className="capability-item">
            <strong>运行环境</strong>
            <span>{props.runtimeInstalled ? '计算环境正常' : '计算环境异常'}</span>
          </div>
          <div className="capability-item">
            <strong>模块状态</strong>
            <span>设计点、非设计点与过渡态可计算</span>
          </div>
        </div>

        <StatsGrid
          items={[
            { label: '运行环境', value: props.runtimeInstalled ? '正常' : '异常' },
            { label: '设计点结果', value: props.designReady ? '已生成' : '未生成' },
            { label: '非设计点结果', value: props.steadyReady ? '已生成' : '未生成' },
            { label: '过渡态结果', value: props.transientReady ? '已生成' : '未生成' },
          ]}
        />
      </Panel>
    </section>
  )
}
