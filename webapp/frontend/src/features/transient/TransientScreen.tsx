import { useDeferredValue } from 'react'

import type { AnyRecord, TransientResponse } from '../../types'
import { formatNumber } from '../../utils'
import { chartTitleMap, linePalette } from '../../components/charts/constants'
import { ScatterPanel } from '../../components/charts/ScatterPanel'
import { SeriesPanel } from '../../components/charts/SeriesPanel'
import { KeyTable } from '../../components/data-display/KeyTable'
import { StatsGrid } from '../../components/data-display/StatsGrid'
import { EmptyState } from '../../components/feedback/EmptyState'
import { InlineInfo } from '../../components/feedback/InlineInfo'
import { LogBlock } from '../../components/feedback/LogBlock'
import { FieldSection } from '../../components/forms/FieldSection'
import { ScheduleEditor } from '../../components/forms/ScheduleEditor'
import { ModuleShell } from '../../components/layout/ModuleShell'
import { Panel } from '../../components/layout/Panel'
import { transientSections } from './transient-sections'

interface TransientScreenProps {
  config: AnyRecord | null
  result: TransientResponse | null
  loadingRows: Array<{ time: number; loading: number }>
  onChange: (path: string, value: unknown) => void
  onAddLoadingRow: () => void
  onRemoveLoadingRow: (index: number) => void
  onUpdateLoadingRow: (index: number, key: 'time' | 'Loading', value: number) => void
  onImportLoadingTable: () => void
  onExportLoadingTable: () => void
  onExportStepTable: () => void
}

export function TransientScreen(props: TransientScreenProps) {
  const config = props.config
  const deferredStepTable = useDeferredValue(props.result?.stepTable ?? [])

  return (
    <ModuleShell
      title="过渡态计算"
      description="设置控制规律与控制参数并查看动态结果。"
      eyebrow="过渡态"
      controls={
        config ? (
          <>
            <InlineInfo label="控制规律表" value={`${props.loadingRows.length} 行`} emphasis="可编辑" />
            <Panel title="控制规律表" description="设置时刻与负载变化。" eyebrow="规律">
              <ScheduleEditor
                rows={props.loadingRows}
                onAdd={props.onAddLoadingRow}
                onRemove={props.onRemoveLoadingRow}
                onUpdate={props.onUpdateLoadingRow}
                onImport={props.onImportLoadingTable}
                onExport={props.onExportLoadingTable}
              />
            </Panel>
            {transientSections.map((section, index) => (
              <FieldSection
                key={section.title}
                config={config}
                section={section}
                defaultOpen={index === 0}
                onChange={props.onChange}
              />
            ))}
          </>
        ) : (
          <EmptyState title="默认参数尚未加载" text="正在加载参数。" compact />
        )
      }
      results={
        props.result ? (
          <>
            <Panel title="结果概览" description="查看动态计算的主要结果。" eyebrow="概览">
              <StatsGrid
                items={[
                  { label: '仿真时长', value: `${formatNumber(props.result.summary.duration_s, 2)} s` },
                  { label: '末时刻功率', value: `${formatNumber(props.result.summary.final_power_kw, 2)} kW` },
                  { label: '末时刻负载', value: `${formatNumber(props.result.summary.final_load_kw, 2)} kW` },
                  { label: '末时刻 T45', value: `${formatNumber(props.result.summary.final_t45_k, 2)} K` },
                ]}
              />
            </Panel>

            <div className="chart-layout chart-layout--transient">
              {Object.entries(props.result.charts).map(([key, series], index) => (
                <SeriesPanel
                  key={key}
                  title={chartTitleMap[key] ?? key}
                  series={series}
                  featured={index === 0}
                />
              ))}
              <ScatterPanel title="HPC 运行轨迹" data={props.result.mapTraces.HPC} color={linePalette[0]} xLabel="Wc" yLabel="PR" />
              <ScatterPanel title="HPT 运行轨迹" data={props.result.mapTraces.HPT} color={linePalette[2]} xLabel="Wc" yLabel="PR" />
              <ScatterPanel title="PT 运行轨迹" data={props.result.mapTraces.PT} color={linePalette[3]} xLabel="Wc" yLabel="PR" />
            </div>

            <Panel
              title="逐时刻结果预览"
              description="默认预览前 60 行，完整结果可导出为 CSV。"
              eyebrow="时序结果"
              actions={<button className="ghost-button" onClick={props.onExportStepTable}>导出完整 CSV</button>}
            >
              <KeyTable rows={deferredStepTable.slice(0, 60) as unknown as Array<Record<string, unknown>>} />
            </Panel>

            {props.result.logs ? (
              <Panel title="运行日志" description="查看本次计算日志。" eyebrow="日志">
                <LogBlock text={props.result.logs} />
              </Panel>
            ) : null}
          </>
        ) : (
          <EmptyState title="还没有过渡态结果" text="先维护控制规律和控制参数，再运行过渡态计算。" accent="Transient" />
        )
      }
    />
  )
}
