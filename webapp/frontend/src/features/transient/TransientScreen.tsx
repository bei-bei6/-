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
      title={'\u8fc7\u6e21\u6001\u8ba1\u7b97'}
      description={'\u914d\u7f6e\u63a7\u5236\u89c4\u5f8b\u4e0e\u63a7\u5236\u53c2\u6570\uff0c\u5e76\u8ffd\u8e2a\u52a8\u6001\u54cd\u5e94\u8fc7\u7a0b\u3002'}
      eyebrow={'\u8fc7\u6e21\u6001'}
      controls={
        config ? (
          <>
            <InlineInfo
              label={'\u63a7\u5236\u89c4\u5f8b\u8868'}
              value={`${props.loadingRows.length} ${'\u884c'}`}
              emphasis={'\u53ef\u7f16\u8f91'}
            />
            <Panel
              title={'\u63a7\u5236\u89c4\u5f8b\u8868'}
              description={'\u914d\u7f6e\u5173\u952e\u65f6\u523b\u7684\u76ee\u6807\u8d1f\u8f7d\u53d8\u5316\u3002'}
              eyebrow={'\u89c4\u5f8b'}
            >
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
          <EmptyState
            title={'\u9ed8\u8ba4\u53c2\u6570\u5c1a\u672a\u52a0\u8f7d'}
            text={'\u7cfb\u7edf\u6b63\u5728\u52a0\u8f7d\u8fc7\u6e21\u6001\u9ed8\u8ba4\u53c2\u6570\u3002'}
            compact
          />
        )
      }
      results={
        props.result ? (
          <>
            <Panel
              title={'\u7ed3\u679c\u6982\u89c8'}
              description={'\u67e5\u770b\u52a8\u6001\u6c42\u89e3\u7684\u5173\u952e\u7ec8\u6001\u4e0e\u4eff\u771f\u5c3a\u5ea6\u3002'}
              eyebrow={'\u6982\u89c8'}
            >
              <StatsGrid
                items={[
                  { label: '\u4eff\u771f\u65f6\u957f', value: `${formatNumber(props.result.summary.duration_s, 2)} s` },
                  { label: '\u672b\u65f6\u523b\u529f\u7387', value: `${formatNumber(props.result.summary.final_power_kw, 2)} kW` },
                  { label: '\u672b\u65f6\u523b\u8d1f\u8f7d', value: `${formatNumber(props.result.summary.final_load_kw, 2)} kW` },
                  { label: '\u672b\u65f6\u523b T45', value: `${formatNumber(props.result.summary.final_t45_k, 2)} K` },
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
              <ScatterPanel title={'HPC \u8fd0\u884c\u8f68\u8ff9'} data={props.result.mapTraces.HPC} color={linePalette[0]} xLabel="Wc" yLabel="PR" />
              <ScatterPanel title={'HPT \u8fd0\u884c\u8f68\u8ff9'} data={props.result.mapTraces.HPT} color={linePalette[2]} xLabel="Wc" yLabel="PR" />
              <ScatterPanel title={'PT \u8fd0\u884c\u8f68\u8ff9'} data={props.result.mapTraces.PT} color={linePalette[3]} xLabel="Wc" yLabel="PR" />
            </div>

            <Panel
              title={'\u9010\u65f6\u523b\u7ed3\u679c\u9884\u89c8'}
              description={'\u9ed8\u8ba4\u9884\u89c8\u524d 60 \u884c\uff0c\u5b8c\u6574\u7ed3\u679c\u53ef\u5bfc\u51fa\u4e3a CSV\u3002'}
              eyebrow={'\u65f6\u5e8f\u7ed3\u679c'}
              actions={<button className="ghost-button" onClick={props.onExportStepTable}>{'\u5bfc\u51fa\u5b8c\u6574 CSV'}</button>}
            >
              <KeyTable rows={deferredStepTable.slice(0, 60) as unknown as Array<Record<string, unknown>>} />
            </Panel>

            {props.result.logs ? (
              <Panel
                title={'\u8fd0\u884c\u65e5\u5fd7'}
                description={'\u67e5\u770b\u672c\u6b21\u8fc7\u6e21\u6001\u6c42\u89e3\u65e5\u5fd7\u3002'}
                eyebrow={'\u65e5\u5fd7'}
              >
                <LogBlock text={props.result.logs} />
              </Panel>
            ) : null}
          </>
        ) : (
          <EmptyState
            title={'\u8fd8\u6ca1\u6709\u8fc7\u6e21\u6001\u7ed3\u679c'}
            text={'\u5148\u7ef4\u62a4\u63a7\u5236\u89c4\u5f8b\u548c\u63a7\u5236\u53c2\u6570\uff0c\u518d\u542f\u52a8\u8fc7\u6e21\u6001\u8ba1\u7b97\u3002'}
            accent="Transient"
          />
        )
      }
    />
  )
}
