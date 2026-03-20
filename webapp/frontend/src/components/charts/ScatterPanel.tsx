import { useMemo } from 'react'
import { CartesianGrid, ResponsiveContainer, Scatter, ScatterChart, Tooltip, XAxis, YAxis } from 'recharts'

import type { ScatterTracePoint } from '../../types'
import { downsampleRows } from '../../utils'
import { axisLineStyle, axisTickStyle, baseChartMargin, formatChartAxisValue, formatChartTooltipValue } from './formatters'

interface ScatterPanelProps {
  title: string
  data: ScatterTracePoint[]
  color: string
  xLabel?: string
  yLabel?: string
}

export function ScatterPanel(props: ScatterPanelProps) {
  const renderedData = useMemo(() => downsampleRows(props.data, 220), [props.data])

  return (
    <div className="chart-panel">
      <div className="chart-panel__head">
        <div>
          <h4>{props.title}</h4>
          <p>
            {props.xLabel ?? '\u6d41\u91cf'} / {props.yLabel ?? '\u538b\u6bd4'}
          </p>
        </div>
      </div>
      <div className="chart-panel__body">
        <ResponsiveContainer width="100%" height="100%">
          <ScatterChart margin={baseChartMargin}>
            <CartesianGrid strokeDasharray="3 3" stroke="#d4dce2" />
            <XAxis
              type="number"
              dataKey="x"
              tick={axisTickStyle}
              tickLine={false}
              axisLine={axisLineStyle}
              tickMargin={8}
              width={72}
              tickFormatter={formatChartAxisValue}
            />
            <YAxis
              type="number"
              dataKey="y"
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
            <Scatter data={renderedData} fill={props.color} line={{ stroke: props.color, strokeWidth: 2 }} isAnimationActive={false} />
          </ScatterChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
