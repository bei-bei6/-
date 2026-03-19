interface LogBlockProps {
  text: string
}

export function LogBlock(props: LogBlockProps) {
  return (
    <details className="fold-card">
      <summary>展开查看运行日志</summary>
      <pre>{props.text}</pre>
    </details>
  )
}
