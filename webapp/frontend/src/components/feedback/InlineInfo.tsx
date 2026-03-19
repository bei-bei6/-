interface InlineInfoProps {
  label: string
  value: string
  emphasis?: string
}

export function InlineInfo(props: InlineInfoProps) {
  return (
    <div className="inline-info">
      <span>{props.label}</span>
      <strong>{props.value}</strong>
      {props.emphasis ? <small>{props.emphasis}</small> : null}
    </div>
  )
}
