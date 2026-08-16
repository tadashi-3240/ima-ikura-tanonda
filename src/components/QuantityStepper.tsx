type Props = {
  value: number
  onChange: (quantity: number) => void
}

export function QuantityStepper({ value, onChange }: Props) {
  return (
    <div className="flex items-center gap-2">
      <button
        type="button"
        aria-label="数量を減らす"
        className="flex size-12 items-center justify-center rounded-full border border-line bg-surface text-2xl leading-none text-ink"
        onClick={() => onChange(value - 1)}
      >
        −
      </button>
      <span className="min-w-8 text-center text-xl font-semibold tabular-nums">{value}</span>
      <button
        type="button"
        aria-label="数量を増やす"
        className="flex size-12 items-center justify-center rounded-full border border-line bg-surface text-2xl leading-none text-ink"
        onClick={() => onChange(value + 1)}
      >
        ＋
      </button>
    </div>
  )
}
