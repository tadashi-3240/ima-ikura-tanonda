import { formatYen } from '../lib/money'

type Props = {
  total: number
  compact?: boolean
}

export function TotalDisplay({ total, compact = false }: Props) {
  return (
    <section className={`px-4 text-center ${compact ? 'pt-0 pb-2' : 'pt-1 pb-3'}`}>
      <p
        className={`font-bold tracking-tight text-gold tabular-nums leading-none ${
          compact
            ? 'text-[clamp(2.4rem,11vw,4.2rem)]'
            : 'mt-1 text-[clamp(2.8rem,13vw,4.8rem)]'
        }`}
      >
        {formatYen(total)}
      </p>
    </section>
  )
}
