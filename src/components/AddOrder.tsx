import { useState } from 'react'
import { parseOrderList } from '../lib/parseOrder'
import type { NewOrder, ParsedOrder } from '../types/order'
import { ManualForm } from './ManualForm'

type Mode = 'quick' | 'manual'

type Props = {
  onAdd: (item: NewOrder) => void
}

export function AddOrder({ onAdd }: Props) {
  const [text, setText] = useState('')
  const [mode, setMode] = useState<Mode>('quick')
  const [parsed, setParsed] = useState<ParsedOrder | null>(null)
  const [error, setError] = useState('')

  const resetQuick = () => {
    setMode('quick')
    setParsed(null)
    setText('')
    setError('')
  }

  const submitText = () => {
    const items = parseOrderList(text)
    if (items.length === 0) {
      setError('商品名と金額を入力してください。例: ビール650円を2つ、カルビ880円を3つ')
      return
    }
    setError('')
    const unnamed = items.find((item) => !item.name)
    if (items.length === 1 && unnamed) {
      setParsed(unnamed)
      setMode('manual')
      return
    }
    for (const item of items) {
      if (item.name) onAdd(item)
    }
    resetQuick()
  }

  return (
    <div className="shrink-0 border-t border-line bg-bg px-3 pt-3 pb-safe">
      {mode === 'manual' && (
        <div className="rounded-2xl border border-line bg-card p-4">
          <p className="mb-3 font-semibold">手入力</p>
          <ManualForm
            initial={parsed ?? { quantity: 1 }}
            onSubmit={(item) => {
              onAdd(item)
              resetQuick()
            }}
            onCancel={resetQuick}
          />
        </div>
      )}

      {mode === 'quick' && (
        <>
          <form
            className="space-y-2"
            onSubmit={(event) => {
              event.preventDefault()
              submitText()
            }}
          >
            <input
              value={text}
              onChange={(event) => {
                setText(event.target.value)
                if (error) setError('')
              }}
              placeholder="ビール2つ650円、カルビ3つ880円"
              aria-label="注文"
              enterKeyHint="done"
              autoCapitalize="none"
              autoComplete="off"
              className="h-14 w-full rounded-2xl border border-line bg-card px-4 text-base"
            />
            <button
              type="submit"
              className="h-14 w-full rounded-2xl bg-gold text-lg font-bold text-bg"
            >
              追加
            </button>
          </form>
          <div className="mt-2 flex items-center justify-between gap-3">
            <p className="min-h-5 text-sm text-danger">{error}</p>
            <button
              type="button"
              className="text-sm text-muted underline"
              onClick={() => {
                setParsed(null)
                setMode('manual')
              }}
            >
              手入力
            </button>
          </div>
        </>
      )}
    </div>
  )
}
