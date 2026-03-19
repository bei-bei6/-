import clsx from 'clsx'
import { useMemo } from 'react'
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'

import type { ChartSeries } from '../../types'
import { buildMergedChartRows } from '../../utils'
import { linePalette } from './constants'
import { axisLineStyle, axisTickStyle, baseChartMargin, formatChartAxisValue, formatChartTooltipValue } from './formatters'

interface SeriesPanelProps {
  title: string
  description?: string
  series: ChartSeries[]
  featured?: boolean
}

export function SeriesPanel(props: SeriesPanelProps) {
  const rows = useMemo(() => buildMergedChartRows(props.series), [props.series])

  return (
    <div className={clsx('chart-panel', { featured: props.featured })}>
      <div className="chart-panel__head">
        <div>
          <h4>{props.title}</h4>
          {props.description ? <p>{props.description}</p> : null}
        </div>
      </div>
      <div className="chart-panel__body">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={rows} margin={baseChartMargin}>
            <CartesianGrid strokeDasharray="3 3" stroke="#d4dce2" />
            <XAxis
              dataKey="time"
              tick={axisTickStyle}
              tickLine={false}
              axisLine={axisLineStyle}
              tickMargin={8}
              minTickGap={20}
              padding={{ left: 8, right: 8 }}
              interval="preserveStartEnd"
              tickFormatter={formatChartAxisValue}
            />
            <YAxis
              tick={axisTickStyle}
              tickLine={false}
              axisLine={axisLineStyle}
              tickMargin={8}
              width={72}
              tickFormatter={formatChartAxisValue}
            />
            <Tooltip
              allowEscapeViewBox={{ x: true, y: true }}
              wrapperStyle={{ zIndex: 20, pointerEvents: 'none' }}
              isAnimationActive={false}
              formatter={(value: unknown, name: string | number | undefined) => [formatChartTooltipValue(value), name ?? '']}
              contentStyle={{ borderRadius: 12, borderColor: '#d7e1e8' }}
            />
            {props.series.map((item, index) => (
              <Line
                key={item.name}
                type="linear"
                dataKey={item.name}
                name={`${item.name} (${item.unit})`}
                stroke={linePalette[index % linePalette.length]}
                strokeWidth={2.4}
                dot={false}
                activeDot={false}
                strokeLinecap="round"
                strokeLinejoin="round"
                isAnimationActive={false}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </div>
      <div className="chart-panel__legend">
        {props.series.map((item, index) => (
          <div key={item.name} className="chart-panel__legend-item">
            <span className="chart-panel__legend-swatch" style={{ backgroundColor: linePalette[index % linePalette.length] }} />
            <span className="chart-panel__legend-label">{item.name} ({item.unit})</span>
          </div>
        ))}
      </div>
    </div>
  )
}
