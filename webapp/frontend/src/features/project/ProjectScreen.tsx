import type { DesignPointResponse, SteadyResponse, TransientResponse } from '../../types'
import { StatsGrid } from '../../components/data-display/StatsGrid'
import { InlineInput } from '../../components/forms/InlineInput'
import { Panel } from '../../components/layout/Panel'

interface ProjectScreenProps {
  projectName: string
  topologyName: string
  projectSnapshot: unknown
  designResult: DesignPointResponse | null
  steadyResult: SteadyResponse | null
  transientResult: TransientResponse | null
  onProjectNameChange: (value: string) => void
  onNewProject: () => void
  onOpenProject: () => void
  onSaveProject: () => void
  onSaveProjectAs: () => void
  onExportDesignStations: () => void
  onExportSteadyPoints: () => void
  onExportTransientSteps: () => void
  onExportLoadingTable: () => void
}

export function ProjectScreen(props: ProjectScreenProps) {
  return (
    <section className="overview-grid project-grid">
      <Panel title="项目文件管理" description="管理当前项目快照与本地保存。" eyebrow="项目">
        <div className="project-stack">
          <InlineInput label="项目名称" hint="本地保存时会作为文件名" value={props.projectName} onChange={props.onProjectNameChange} />
          <div className="button-row">
            <button className="ghost-button" onClick={props.onNewProject}>新建</button>
            <button className="ghost-button" onClick={props.onOpenProject}>打开</button>
            <button className="ghost-button" onClick={props.onSaveProject}>保存</button>
            <button className="ghost-button" onClick={props.onSaveProjectAs}>另存为</button>
          </div>
        </div>

        <StatsGrid
          items={[
            { label: '设计点结果', value: props.designResult ? '已写入项目' : '暂无' },
            { label: '非设计点结果', value: props.steadyResult ? '已写入项目' : '暂无' },
            { label: '过渡态结果', value: props.transientResult ? '已写入项目' : '暂无' },
            { label: '当前拓扑', value: props.topologyName },
          ]}
        />
      </Panel>

      <Panel title="数据导出" description="导出计算结果与控制规律模板。" eyebrow="导出">
        <div className="button-row button-row--wrap">
          <button className="ghost-button" disabled={!props.designResult} onClick={props.onExportDesignStations}>导出设计点站位表</button>
          <button className="ghost-button" disabled={!props.steadyResult} onClick={props.onExportSteadyPoints}>导出非设计点结果</button>
          <button className="ghost-button" disabled={!props.transientResult} onClick={props.onExportTransientSteps}>导出过渡态结果</button>
          <button className="ghost-button" onClick={props.onExportLoadingTable}>导出负载模板</button>
        </div>
        <details className="fold-card">
          <summary>查看当前项目 JSON 快照</summary>
          <pre>{JSON.stringify(props.projectSnapshot, null, 2)}</pre>
        </details>
      </Panel>
    </section>
  )
}
