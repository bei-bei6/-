interface InlineInputProps {
  label: string
  hint?: string
  value: string
  onChange: (value: string) => void
}

export function InlineInput(props: InlineInputProps) {
  return (
    <label className="inline-input">
      <span>{props.label}</span>
      <input value={props.value} onChange={(event) => props.onChange(event.target.value)} />
      {props.hint ? <small>{props.hint}</small> : null}
    </label>
  )
}
