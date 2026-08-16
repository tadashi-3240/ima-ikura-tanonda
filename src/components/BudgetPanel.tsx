import { useState } from 'react'
import { formatYen, parseYenInput, remainingBudget } from '../lib/money'

type Props = {
  budget: number | null
  total: number
  onChange: (budget: number | null) => void
}

export function BudgetPanel({ budget, total, onChange }: Props) {
  const [editing, setEditing] = useState(false)
  const [draft, setDraft] = useState(budget === null ? '' : String(budget))
  const remaining = remainingBudget(budget, total)

  const save = () => {
    const parsed = parseYenInput(draft)
    onChange(parsed)
    setEditing(false)
  }

  if (editing) {
    return (
      <section className="mx-4 mb-3 rounded-2xl border border-line bg-card p-3">
        <label className="block text-sm text-muted" htmlFor="budget-input">
          予算（任意）
        </label>
        <div className="mt-2 flex gap-2">
          <input
            id="budget-input"
            inputMode="numeric"
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            placeholder="15000"
            className="h-12 min-w-0 flex-1 rounded-xl border border-line bg-surface px-3 text-lg tabular-nums"
            autoFocus
          />
          <button
            type="button"
            className="h-12 rounded-xl bg-gold px-4 font-bold text-bg"
            onClick={save}
          >
            設定
          </button>
        </div>
        {budget !== null && (
          <button
            type="button"
            className="mt-2 text-sm text-muted underline"
            onClick={() => {
              onChange(null)
              setDraft('')
              setEditing(false)
            }}
          >
            予算を解除
          </button>
        )}
      </section>
    )
  }

  if (budget === null || remaining === null) {
    return (
      <div className="mb-3 flex justify-center">
        <button
          type="button"
          className="text-sm text-muted underline"
          onClick={() => setEditing(true)}
        >
          予算を設定
        </button>
      </div>
    )
  }

  const over = remaining < 0

  return (
    <section className="mx-4 mb-3 rounded-2xl border border-line bg-card px-4 py-3 text-center">
      <div className="flex items-center justify-center gap-4 text-sm text-muted">
        <span>予算 {formatYen(budget)}</span>
        <button type="button" className="underline" onClick={() => setEditing(true)}>
          変更
        </button>
      </div>
      {over ? (
        <p className="mt-1 text-xl font-bold text-danger tabular-nums">
          {formatYen(-remaining)}オーバー
        </p>
      ) : (
        <p className="mt-1 text-lg font-semibold text-ok tabular-nums">残り {formatYen(remaining)}</p>
      )}
    </section>
  )
}
