import { formatYen } from '../lib/money'

type Props = {
  total: number
}

export function TotalDisplay({ total }: Props) {
  return (
    <section className="px-4 pt-1 pb-3 text-center">
      <p className="text-sm font-medium tracking-wide text-muted">現在の合計</p>
      <p className="mt-1 font-bold tracking-tight text-gold tabular-nums text-[clamp(2.8rem,13vw,4.8rem)] leading-none">
        {formatYen(total)}
      </p>
    </section>
  )
}
