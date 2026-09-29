import { useState, type ReactNode } from 'react'
import { formatYen, grandTotal, lineSubtotal } from '../lib/money'
import type { NewOrder, ParsedOrder } from '../types/order'
import { ManualForm } from './ManualForm'
import { QuantityStepper } from './QuantityStepper'

type Draft = ParsedOrder & { key: string }

type Props = {
  initial: ParsedOrder[]
  spoken?: string
  resetButton?: ReactNode
  onConfirm: (items: NewOrder[]) => void
  onBack: () => void
}

function toDraft(items: ParsedOrder[]): Draft[] {
  return items.map((item, index) => ({ ...item, key: `${item.name}-${item.unitPrice}-${index}` }))
}

export function OpeningReview({ initial, spoken, resetButton, onConfirm, onBack }: Props) {
  const [drafts, setDrafts] = useState<Draft[]>(() => toDraft(initial))
  const [adding, setAdding] = useState(false)
  const [editingKey, setEditingKey] = useState<string | null>(null)
  const [error, setError] = useState('')
  const editing = drafts.find((item) => item.key === editingKey) ?? null
  const total = grandTotal(drafts)

  const confirm = () => {
    const ready = drafts.filter((item) => item.name.trim() && item.unitPrice > 0)
    if (ready.length === 0) {
      setError('残す商品の名前と金額を入れてください')
      return
    }
    if (ready.length !== drafts.length) {
      setError('名前か金額が空の品があります。直すか削除してください')
      return
    }
    onConfirm(ready.map(({ name, unitPrice, quantity }) => ({ name, unitPrice, quantity })))
  }

  return (
    <div className="mx-auto flex h-dvh w-full max-w-3xl flex-col overflow-hidden bg-bg pt-safe pb-safe">
      <header className="relative shrink-0 border-b border-line/50 px-4 pt-5 pb-3 text-center">
        {resetButton}
        <h1 className="px-16 text-2xl font-bold tracking-wide">今いくら頼んだ？</h1>
        <p className="mt-1 text-sm text-muted">違っていたら、ここで直してください。</p>
        <p className="mt-3 font-bold tracking-tight text-gold tabular-nums text-[clamp(2.4rem,11vw,4.2rem)] leading-none">
          {formatYen(total)}
        </p>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto px-4 py-4">
        {spoken ? <p className="mb-3 text-sm text-muted">「{spoken}」</p> : null}
        <ul className="space-y-3">
          {drafts.map((item) => (
            <li key={item.key} className="rounded-2xl border border-line bg-card p-4">
              <div className="flex items-start justify-between gap-3">
                <p className="text-lg font-bold leading-tight">{item.name || '（商品名なし）'}</p>
                <button
                  type="button"
                  className="shrink-0 text-sm text-muted underline"
                  onClick={() => setEditingKey(item.key)}
                >
                  修正
                </button>
              </div>
              <p className="mt-1 text-muted tabular-nums">
                {formatYen(item.unitPrice)} × {item.quantity}
              </p>
              <div className="mt-3 flex items-center justify-between gap-3">
                <p className="text-2xl font-bold text-gold tabular-nums">
                  {formatYen(lineSubtotal(item.unitPrice, item.quantity))}
                </p>
                <QuantityStepper
                  value={item.quantity}
                  onChange={(quantity) =>
                    setDrafts((prev) =>
                      prev.map((row) =>
                        row.key === item.key ? { ...row, quantity: Math.max(1, quantity) } : row,
                      ),
                    )
                  }
                />
              </div>
              <button
                type="button"
                className="mt-3 text-sm text-danger underline"
                onClick={() => setDrafts((prev) => prev.filter((row) => row.key !== item.key))}
              >
                削除
              </button>
            </li>
          ))}
        </ul>
        {adding ? (
          <div className="mt-4 rounded-2xl border border-line bg-card p-4">
            <p className="mb-3 font-semibold">品を足す</p>
            <ManualForm
              submitLabel="足す"
              onSubmit={(item) => {
                setDrafts((prev) => [...prev, { ...item, key: `${item.name}-${Date.now()}` }])
                setAdding(false)
              }}
              onCancel={() => setAdding(false)}
            />
          </div>
        ) : (
          <button
            type="button"
            className="mt-4 h-12 w-full rounded-2xl border border-line text-muted"
            onClick={() => setAdding(true)}
          >
            品を足す
          </button>
        )}
        {error ? <p className="mt-3 text-sm text-danger">{error}</p> : null}
      </div>

      <div className="shrink-0 space-y-2 border-t border-line px-4 pt-3 pb-3">
        <button
          type="button"
          className="h-14 w-full rounded-2xl bg-gold text-lg font-bold text-bg"
          onClick={confirm}
        >
          この内容で始める
        </button>
        <button type="button" className="h-11 w-full text-sm text-muted underline" onClick={onBack}>
          聞き直す
        </button>
      </div>

      {editing && (
        <div className="fixed inset-0 z-40 flex items-end justify-center bg-black/55 p-4 sm:items-center">
          <div className="w-full max-w-md rounded-3xl border border-line bg-surface p-5">
            <h2 className="mb-4 text-lg font-bold">注文を修正</h2>
            <ManualForm
              key={editing.key}
              initial={editing}
              submitLabel="保存"
              onSubmit={(item) => {
                setDrafts((prev) =>
                  prev.map((row) => (row.key === editing.key ? { ...row, ...item } : row)),
                )
                setEditingKey(null)
              }}
              onCancel={() => setEditingKey(null)}
            />
          </div>
        </div>
      )}
    </div>
  )
}
