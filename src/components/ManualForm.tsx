import { useState } from 'react'
import { parseYenInput } from '../lib/money'
import type { NewOrder } from '../types/order'
import { QuantityStepper } from './QuantityStepper'

type Props = {
  initial?: Partial<NewOrder>
  submitLabel?: string
  onSubmit: (item: NewOrder) => void
  onCancel?: () => void
}

export function ManualForm({ initial, submitLabel = '追加', onSubmit, onCancel }: Props) {
  const [name, setName] = useState(initial?.name ?? '')
  const [price, setPrice] = useState(
    initial?.unitPrice != null && initial.unitPrice > 0 ? String(initial.unitPrice) : '',
  )
  const [quantity, setQuantity] = useState(initial?.quantity ?? 1)
  const [error, setError] = useState('')

  const submit = () => {
    const trimmed = name.trim()
    const unitPrice = parseYenInput(price)
    if (!trimmed) {
      setError('商品名を入力してください')
      return
    }
    if (unitPrice === null || unitPrice <= 0) {
      setError('単価を入力してください')
      return
    }
    onSubmit({ name: trimmed, unitPrice, quantity: Math.max(1, quantity) })
  }

  return (
    <form
      className="space-y-3"
      onSubmit={(event) => {
        event.preventDefault()
        submit()
      }}
    >
      <label className="block">
        <span className="text-sm text-muted">商品名</span>
        <input
          value={name}
          onChange={(event) => setName(event.target.value)}
          className="mt-1 h-12 w-full rounded-xl border border-line bg-surface px-3"
          autoComplete="off"
        />
      </label>
      <label className="block">
        <span className="text-sm text-muted">単価</span>
        <input
          value={price}
          onChange={(event) => setPrice(event.target.value)}
          inputMode="numeric"
          className="mt-1 h-12 w-full rounded-xl border border-line bg-surface px-3 tabular-nums"
        />
      </label>
      <div>
        <span className="text-sm text-muted">数量</span>
        <div className="mt-1">
          <QuantityStepper value={quantity} onChange={(value) => setQuantity(Math.max(1, value))} />
        </div>
      </div>
      {error && <p className="text-sm text-danger">{error}</p>}
      <div className="flex gap-2">
        <button type="submit" className="h-14 flex-1 rounded-2xl bg-gold text-lg font-bold text-bg">
          {submitLabel}
        </button>
        {onCancel && (
          <button
            type="button"
            className="h-14 rounded-2xl border border-line px-4 text-muted"
            onClick={onCancel}
          >
            戻る
          </button>
        )}
      </div>
    </form>
  )
}
