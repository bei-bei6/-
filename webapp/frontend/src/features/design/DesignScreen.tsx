import type { AnyRecord, DesignPointResponse } from '../../types'
import { formatNumber } from '../../utils'
import { EmptyState } from '../../components/feedback/EmptyState'
import { InlineInfo } from '../../components/feedback/InlineInfo'
import { LogBlock } from '../../components/feedback/LogBlock'
import { StationTable } from '../../components/data-display/StationTable'
import { StatsGrid } from '../../components/data-display/StatsGrid'
import { FieldSection } from '../../components/forms/FieldSection'
import { ModuleShell } from '../../components/layout/ModuleShell'
import { Panel } from '../../components/layout/Panel'
import { designSections } from './design-sections'

interface DesignScreenProps {
  config: AnyRecord | null
  result: DesignPointResponse | null
  onChange: (path: string, value: unknown) => void
}

export function DesignScreen(props: DesignScreenProps) {
  const config = props.config

  return (
    <ModuleShell
      title="设计点计算"
      description="配置设计点参数，并查看功率、效率与站位结果。"
      eyebrow="设计点"
      controls={
        config ? (
          <>
            <InlineInfo label="计算模式" value="设计点" emphasis="当前参数集" />
            {designSections.map((section, index) => (
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
          <EmptyState title="默认参数尚未加载" text="系统正在加载设计点默认参数。" compact />
        )
      }
      results={
        props.result ? (
          <>
            <Panel title="核心指标" description="查看功率、效率和轴系转速的设计点结果。" eyebrow="结果">
              <StatsGrid
                items={[
                  { label: '输出功率', value: `${formatNumber(props.result.summary.power_output_kw, 2)} kW` },
                  { label: '热效率', value: formatNumber(props.result.summary.thermal_efficiency, 6) },
                  { label: '高压轴转速', value: `${formatNumber(props.result.summary.ng_rpm, 2)} rpm` },
                  { label: '动力轴转速', value: `${formatNumber(props.result.summary.np_rpm, 2)} rpm` },
                ]}
              />
            </Panel>

            <Panel title="站位结果表" description="查看主要站位的温度、压力与流量数据。" eyebrow="站位">
              <StationTable rows={props.result.summary.stations ?? []} />
            </Panel>

            <Panel title="设计点产物" description="检查本次计算导出的核心中间结果。" eyebrow="产物">
              <div className="insight-grid insight-grid--two">
                <details className="fold-card">
                  <summary>查看 dp</summary>
                  <pre>{JSON.stringify(props.result.dp, null, 2)}</pre>
                </details>
                <details className="fold-card">
                  <summary>查看 scale</summary>
                  <pre>{JSON.stringify(props.result.scale, null, 2)}</pre>
                </details>
              </div>
            </Panel>

            {props.result.logs ? (
              <Panel title="运行日志" description="查看本次设计点计算日志。" eyebrow="日志">
                <LogBlock text={props.result.logs} />
              </Panel>
            ) : null}
          </>
        ) : (
          <EmptyState title="还没有设计点结果" text="先在左侧调整参数，再启动设计点计算。" accent="Design" />
        )
      }
    />
  )
}
