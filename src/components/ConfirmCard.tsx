import { formatYen, lineSubtotal } from '../lib/money'
import type { ParsedOrder } from '../types/order'

type Props = {
  parsed: ParsedOrder
  onAdd: () => void
  onEdit: () => void
}

export function ConfirmCard({ parsed, onAdd, onEdit }: Props) {
  const subtotal = lineSubtotal(parsed.unitPrice, parsed.quantity)

  return (
    <section className="rounded-2xl border border-gold/40 bg-card p-4">
      <p className="text-xl font-bold">{parsed.name || '（商品名なし）'}</p>
      <p className="mt-1 text-muted tabular-nums">
        {formatYen(parsed.unitPrice)} × {parsed.quantity}
      </p>
      <p className="mt-1 text-2xl font-bold text-gold tabular-nums">{formatYen(subtotal)}</p>
      <div className="mt-4 flex flex-col gap-2">
        <button
          type="button"
          className="h-14 w-full rounded-2xl bg-gold text-lg font-bold text-bg"
          onClick={onAdd}
        >
          追加する
        </button>
        <button
          type="button"
          className="h-11 w-full rounded-2xl border border-line text-muted"
          onClick={onEdit}
        >
          修正
        </button>
      </div>
    </section>
  )
}
