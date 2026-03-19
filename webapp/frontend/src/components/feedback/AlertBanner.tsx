import clsx from 'clsx'

interface AlertBannerProps {
  tone: 'info' | 'error'
  message: string
}

export function AlertBanner(props: AlertBannerProps) {
  return <div className={clsx('alert', props.tone)}>{props.message}</div>
}
