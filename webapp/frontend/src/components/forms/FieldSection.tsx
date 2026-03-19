import { getByPath, listToText, numberValue, parseNumericList } from '../../utils'
import type { AnyRecord } from '../../types'
import type { SectionSpec } from './types'

interface FieldSectionProps {
  config: AnyRecord
  section: SectionSpec
  defaultOpen?: boolean
  onChange: (path: string, value: unknown) => void
}

export function FieldSection(props: FieldSectionProps) {
  return (
    <details className="field-section" open={props.defaultOpen}>
      <summary>
        <span>{props.section.title}</span>
        {props.section.description ? <small>{props.section.description}</small> : null}
      </summary>
      <div className="field-grid">
        {props.section.fields.map((field) => {
          const rawValue = getByPath(props.config, field.path)
          const kind = field.kind ?? 'number'
          return (
            <label key={field.path} className="field-card">
              <span className="field-label">{field.label}</span>
              {kind === 'boolean' ? (
                <select value={numberValue(rawValue, 0)} onChange={(event) => props.onChange(field.path, Number(event.target.value))}>
                  <option value={1}>开启</option>
                  <option value={0}>关闭</option>
                </select>
              ) : kind === 'list' ? (
                <input
                  type="text"
                  placeholder={field.placeholder}
                  value={listToText(rawValue)}
                  onChange={(event) => props.onChange(field.path, parseNumericList(event.target.value))}
                />
              ) : (
                <input
                  type="number"
                  step={field.step ?? '0.001'}
                  placeholder={field.placeholder}
                  value={numberValue(rawValue, 0)}
                  onChange={(event) => props.onChange(field.path, Number(event.target.value))}
                />
              )}
              <div className="field-meta">
                <small>{field.unit ?? ' '}</small>
                {field.hint ? <small>{field.hint}</small> : null}
              </div>
            </label>
          )
        })}
      </div>
    </details>
  )
}
