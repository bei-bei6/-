interface ScheduleEditorProps {
  rows: Array<{ time: number; loading: number }>
  onAdd: () => void
  onRemove: (index: number) => void
  onUpdate: (index: number, key: 'time' | 'Loading', value: number) => void
  onImport: () => void
  onExport: () => void
}

export function ScheduleEditor(props: ScheduleEditorProps) {
  return (
    <div className="schedule-editor">
      <div className="detail-toolbar detail-toolbar--stack">
        <button className="ghost-button" onClick={props.onAdd}>添加行</button>
        <button className="ghost-button" onClick={props.onImport}>导入 CSV</button>
        <button className="ghost-button" onClick={props.onExport}>导出 CSV</button>
      </div>
      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>时间 / s</th>
              <th>负载 / MW</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            {props.rows.map((row, index) => (
              <tr key={`${row.time}-${index}`}>
                <td>
                  <input
                    className="table-input"
                    type="number"
                    step="0.01"
                    value={row.time}
                    onChange={(event) => props.onUpdate(index, 'time', Number(event.target.value))}
                  />
                </td>
                <td>
                  <input
                    className="table-input"
                    type="number"
                    step="0.01"
                    value={row.loading}
                    onChange={(event) => props.onUpdate(index, 'Loading', Number(event.target.value))}
                  />
                </td>
                <td>
                  <button className="table-button" onClick={() => props.onRemove(index)}>
                    删除
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
