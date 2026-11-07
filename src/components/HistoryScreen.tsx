import { useState } from 'react'
import { groupByCategory } from '../lib/category'
import { formatSavedAt } from '../lib/history'
import { formatYen, grandTotal, lineSubtotal } from '../lib/money'
import type { SavedBill } from '../types/order'

type Props = {
  bills: SavedBill[]
  onBack: () => void
  onRemove: (id: string) => void
}

export function HistoryScreen({ bills, onBack, onRemove }: Props) {
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const selected = bills.find((bill) => bill.id === selectedId) ?? null

  if (selected) {
    const total = grandTotal(selected.orders)
    const groups = groupByCategory(selected.orders)
    return (
      <div className="mx-auto flex h-dvh w-full max-w-3xl flex-col overflow-hidden bg-bg pt-safe pb-safe">
        <header className="relative shrink-0 border-b border-line/50 px-4 pt-5 pb-3 text-center">
          <button
            type="button"
            className="absolute left-4 top-5 z-10 h-11 rounded-xl px-3 text-sm text-muted"
            onClick={() => setSelectedId(null)}
          >
            戻る
          </button>
          <h1 className="px-16 text-xl font-bold tracking-wide">
            {selected.placeName ?? '過去の注文'}
          </h1>
          <p className="mt-1 text-sm text-muted">{formatSavedAt(selected.savedAt)}</p>
          <p className="mt-3 font-bold tracking-tight text-gold tabular-nums text-[clamp(2.4rem,11vw,4.2rem)] leading-none">
            {formatYen(total)}
          </p>
        </header>

        <div className="min-h-0 flex-1 overflow-y-auto px-4 py-4">
          <div className="space-y-6">
            {groups.map((group) => (
              <section key={group.category}>
                <h2 className="mb-2 text-sm font-semibold text-muted">{group.category}</h2>
                <ul className="space-y-3">
                  {group.items.map((order) => (
                    <li key={order.id} className="rounded-2xl border border-line bg-card p-4">
                      <p className="text-lg font-bold leading-tight">{order.name}</p>
                      <p className="mt-1 text-muted tabular-nums">
                        {formatYen(order.unitPrice)} × {order.quantity}
                      </p>
                      <p className="mt-2 text-xl font-bold text-gold tabular-nums">
                        {formatYen(lineSubtotal(order.unitPrice, order.quantity))}
                      </p>
                    </li>
                  ))}
                </ul>
              </section>
            ))}
          </div>
        </div>

        <div className="shrink-0 border-t border-line px-4 pt-3 pb-3">
          <button
            type="button"
            className="h-12 w-full rounded-2xl border border-danger/40 text-danger"
            onClick={() => {
              onRemove(selected.id)
              setSelectedId(null)
            }}
          >
            この履歴を削除
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="mx-auto flex h-dvh w-full max-w-3xl flex-col overflow-hidden bg-bg pt-safe pb-safe">
      <header className="relative shrink-0 border-b border-line/50 px-4 pt-5 pb-3 text-center">
        <button
          type="button"
          className="absolute left-4 top-5 z-10 h-11 rounded-xl px-3 text-sm text-muted"
          onClick={onBack}
        >
          戻る
        </button>
        <h1 className="px-16 text-2xl font-bold tracking-wide">履歴</h1>
        <p className="mt-1 text-sm text-muted">リセットした会計を後から見られます。</p>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto px-4 py-4">
        {bills.length === 0 ? (
          <p className="px-2 py-10 text-center text-muted">まだ履歴はありません。</p>
        ) : (
          <ul className="space-y-3">
            {bills.map((bill) => (
              <li key={bill.id}>
                <button
                  type="button"
                  className="flex w-full items-center justify-between gap-3 rounded-2xl border border-line bg-card px-4 py-4 text-left"
                  onClick={() => setSelectedId(bill.id)}
                >
                  <div className="min-w-0">
                    <p className="truncate font-semibold">
                      {bill.placeName ?? '店名なし'}
                    </p>
                    <p className="mt-1 text-sm text-muted">{formatSavedAt(bill.savedAt)}</p>
                    <p className="mt-0.5 text-sm text-muted">{bill.orders.length}品</p>
                  </div>
                  <p className="text-xl font-bold text-gold tabular-nums">
                    {formatYen(grandTotal(bill.orders))}
                  </p>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
