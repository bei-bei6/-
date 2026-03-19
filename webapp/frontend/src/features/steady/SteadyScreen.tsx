import type { AnyRecord, SteadyResponse } from '../../types'
import { formatNumber } from '../../utils'
import { linePalette } from '../../components/charts/constants'
import { LinePanel } from '../../components/charts/LinePanel'
import { ScatterPanel } from '../../components/charts/ScatterPanel'
import { ObjectCards } from '../../components/data-display/ObjectCards'
import { StationTable } from '../../components/data-display/StationTable'
import { StatsGrid } from '../../components/data-display/StatsGrid'
import { EmptyState } from '../../components/feedback/EmptyState'
import { InlineInfo } from '../../components/feedback/InlineInfo'
import { LogBlock } from '../../components/feedback/LogBlock'
import { FieldSection } from '../../components/forms/FieldSection'
import { InlineInput } from '../../components/forms/InlineInput'
import { ModuleShell } from '../../components/layout/ModuleShell'
import { Panel } from '../../components/layout/Panel'
import { steadySections } from './steady-sections'

interface SteadyScreenProps {
  config: AnyRecord | null
  loadsText: string
  onLoadsChange: (value: string) => void
  result: SteadyResponse | null
  activeRunIndex: number
  onActiveRunChange: (index: number) => void
  onChange: (path: string, value: unknown) => void
  onExportBatchCsv: () => void
}

export function SteadyScreen(props: SteadyScreenProps) {
  const config = props.config
  const steadyPoints = props.result?.batch.points ?? []
  const activeRun = props.result ? props.result.runs[props.activeRunIndex] ?? props.result.runs[0] : null

  return (
    <ModuleShell
      title="非设计点计算"
      description="设置负载工况并查看稳态结果。"
      eyebrow="非设计点"
      controls={
        config ? (
          <>
            <InlineInfo label="工况模式" value="多工况" emphasis="输入功率点列表" />
            <InlineInput label="功率点列表" hint="输入 MW，例如 8, 10, 12, 13.2" value={props.loadsText} onChange={props.onLoadsChange} />
            {steadySections.map((section, index) => (
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
            <Panel title="工况概览" description="查看本次稳态计算的整体结果。" eyebrow="概览">
              <StatsGrid
                items={[
                  { label: '工况点数', value: props.result.runs.length.toString() },
                  { label: '最大输出功率', value: `${formatNumber(maxOf(steadyPoints.map((item) => item.output_power_kw)), 2)} kW` },
                  { label: '最高热效率', value: formatNumber(maxOf(steadyPoints.map((item) => item.thermal_efficiency)), 6) },
                  { label: '导出状态', value: 'CSV 可导出' },
                ]}
              />
            </Panel>

            <div className="chart-layout chart-layout--steady">
              <LinePanel
                title="负载响应总览"
                description="对比负载输入、输出功率与热效率的变化。"
                rows={steadyPoints as unknown as Array<Record<string, number>>}
                xKey="input_load_mw"
                lines={[
                  { key: 'output_power_kw', name: '输出功率', color: linePalette[0] },
                  { key: 'thermal_efficiency', name: '热效率', color: linePalette[1] },
                ]}
                featured
              />
              <LinePanel
                title="压比变化"
                description="观察不同工况下的压比变化趋势。"
                rows={steadyPoints as unknown as Array<Record<string, number>>}
                xKey="input_load_mw"
                lines={[
                  { key: 'hpc_pr', name: 'HPC PR', color: linePalette[0] },
                  { key: 'hpt_pr', name: 'HPT PR', color: linePalette[2] },
                  { key: 'pt_pr', name: 'PT PR', color: linePalette[3] },
                ]}
              />
              <ScatterPanel title="HPC 共同工作线" data={props.result.batch.workingLines.HPC} color={linePalette[0]} />
              <ScatterPanel title="HPT 共同工作线" data={props.result.batch.workingLines.HPT} color={linePalette[2]} />
              <ScatterPanel title="PT 共同工作线" data={props.result.batch.workingLines.PT} color={linePalette[3]} />
            </div>

            <Panel
              title="工况明细"
              description="查看当前所选工况的详细站位和部件性能。"
              eyebrow="明细"
              actions={
                <div className="detail-toolbar detail-toolbar--inline">
                  <div className="select-group">
                    <label htmlFor="steady-run-select">当前工况</label>
                    <select
                      id="steady-run-select"
                      value={props.activeRunIndex}
                      onChange={(event) => props.onActiveRunChange(Number(event.target.value))}
                    >
                      {props.result.runs.map((run, index) => (
                        <option key={run.inputPowerOutputW} value={index}>
                          {formatNumber(run.inputPowerOutputW / 1_000_000, 2)} MW
                        </option>
                      ))}
                    </select>
                  </div>
                  <button className="ghost-button" onClick={props.onExportBatchCsv}>
                    导出批量结果 CSV
                  </button>
                </div>
              }
            >
              {activeRun ? (
                <div className="module-results-stack">
                  <StatsGrid
                    items={[
                      { label: '输出功率', value: `${formatNumber(activeRun.summary.power_output_kw, 2)} kW` },
                      { label: '热效率', value: formatNumber(activeRun.summary.thermal_efficiency, 6) },
                      { label: 'Ng', value: `${formatNumber(activeRun.summary.ng_rpm, 2)} rpm` },
                      { label: '燃油流量', value: `${formatNumber(activeRun.summary.fuel_flow_kg_s, 4)} kg/s` },
                    ]}
                  />
                  <StationTable rows={activeRun.stations} />
                  <ObjectCards title="部件性能卡片" data={activeRun.componentPerformance} />
                </div>
              ) : null}
            </Panel>

            {activeRun?.logs ? (
              <Panel title="运行日志" description="查看当前工况日志。" eyebrow="日志">
                <LogBlock text={activeRun.logs} />
              </Panel>
            ) : null}
          </>
        ) : (
          <EmptyState title="还没有非设计点结果" text="先设置负载点列表，再运行非设计点计算。" accent="Steady" />
        )
      }
    />
  )
}

function maxOf(values: number[]): number {
  return values.length ? Math.max(...values) : 0
}
