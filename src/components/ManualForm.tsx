import { useState } from 'react'
import { useSpeechInput } from '../hooks/useSpeechInput'
import { parseYenInput } from '../lib/money'
import { parseOrderText } from '../lib/parseOrder'
import type { NewOrder } from '../types/order'
import { MicButton } from './MicButton'
import { QuantityStepper } from './QuantityStepper'
import { VoiceField } from './VoiceField'

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

  const applySpoken = (spoken: string) => {
    const result = parseOrderText(spoken)
    if (!result) {
      setName(spoken)
      return
    }
    if (result.name) setName(result.name)
    if (result.unitPrice > 0) setPrice(String(result.unitPrice))
    if (result.quantity >= 1) setQuantity(result.quantity)
  }

  const speech = useSpeechInput({
    onPreview: applySpoken,
    onFinal: applySpoken,
  })

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
        <div className="mt-1 flex items-center gap-2">
          <VoiceField
            value={name}
            showCaret={speech.listening}
            padClass="px-3"
            padPx={12}
            readOnly={speech.listening}
            inputMode={speech.listening ? 'none' : 'text'}
            onChange={(event) => setName(event.target.value)}
            className={`h-12 rounded-xl border bg-surface ${
              speech.listening ? 'border-gold' : 'border-line'
            }`}
            autoComplete="off"
          />
          {speech.available && (
            <MicButton
              listening={speech.listening}
              onToggle={speech.listening ? speech.stop : speech.start}
            />
          )}
        </div>
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
      {speech.listening ? (
        <p className="text-sm text-gold">聞いています。話してください。</p>
      ) : null}
      {(error || speech.error) && <p className="text-sm text-danger">{error || speech.error}</p>}
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
