import type { ReactNode } from 'react'
import { useState } from 'react'
import { parseOrderList } from '../lib/parseOrder'
import type { ParsedOrder } from '../types/order'

type Props = {
  initialText?: string
  resetButton?: ReactNode
  onParsed: (items: ParsedOrder[], spoken: string) => void
  onSkip: () => void
}

export function OpeningCapture({ initialText = '', resetButton, onParsed, onSkip }: Props) {
  const [text, setText] = useState(initialText)
  const [error, setError] = useState('')

  const submit = () => {
    const raw = text.trim()
    const items = parseOrderList(raw)
    if (items.length === 0) {
      setError('商品名と金額が読み取れませんでした。例: ビール2つ650円、カルビ3つ880円')
      return
    }
    onParsed(items, raw)
  }

  return (
    <div className="mx-auto flex h-dvh w-full max-w-3xl flex-col overflow-hidden bg-bg pt-safe pb-safe">
      <header className="relative shrink-0 px-4 pt-6 text-center">
        {resetButton}
        <h1 className="px-16 text-2xl font-bold tracking-wide sm:text-3xl">今いくら頼んだ？</h1>
        <p className="mt-2 text-sm text-muted">
          最初はまとめて入れてください。あとから直せます。
        </p>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto px-4 py-4">
        <textarea
          value={text}
          onChange={(event) => {
            setText(event.target.value)
            if (error) setError('')
          }}
          placeholder={'ビール2つ650円、カルビ3つ880円、餃子1100円を2つ'}
          aria-label="まとめて注文"
          className="min-h-40 w-full resize-none rounded-2xl border border-line bg-card px-4 py-3 text-base leading-relaxed"
        />
        <p className="mt-2 text-sm text-muted">「何がいくつ、いくら」を続けてどうぞ。</p>
        {error ? <p className="mt-2 text-sm text-danger">{error}</p> : null}
      </div>

      <div className="shrink-0 space-y-2 border-t border-line px-4 pt-3 pb-3">
        <button
          type="button"
          className="h-14 w-full rounded-2xl bg-gold text-lg font-bold text-bg"
          onClick={submit}
        >
          読み取る
        </button>
        <button type="button" className="h-11 w-full text-sm text-muted underline" onClick={onSkip}>
          1品ずつ入れる
        </button>
      </div>
    </div>
  )
}
