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

import { downsampleRows } from '../../utils'
import { axisLineStyle, axisTickStyle, baseChartMargin, formatChartAxisValue, formatChartTooltipValue } from './formatters'

interface LinePanelProps {
  title: string
  description?: string
  rows: Array<Record<string, number>>
  xKey: string
  lines: Array<{ key: string; name: string; color: string }>
  featured?: boolean
}

export function LinePanel(props: LinePanelProps) {
  const renderedRows = useMemo(() => downsampleRows(props.rows, props.lines.length > 3 ? 160 : 220), [props.lines.length, props.rows])

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
          <LineChart data={renderedRows} margin={baseChartMargin}>
            <CartesianGrid strokeDasharray="3 3" stroke="#d4dce2" />
            <XAxis
              dataKey={props.xKey}
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
              cursor={false}
              formatter={(value: unknown, name: string | number | undefined) => [formatChartTooltipValue(value), name ?? '']}
              contentStyle={{ borderRadius: 12, borderColor: '#d7e1e8' }}
            />
            {props.lines.map((line) => (
              <Line
                key={line.key}
                type="linear"
                dataKey={line.key}
                name={line.name}
                stroke={line.color}
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
        {props.lines.map((line) => (
          <div key={line.key} className="chart-panel__legend-item">
            <span className="chart-panel__legend-swatch" style={{ backgroundColor: line.color }} />
            <span className="chart-panel__legend-label">{line.name}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
