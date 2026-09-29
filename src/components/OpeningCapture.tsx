import type { ReactNode } from 'react'
import { useRef, useState } from 'react'
import { useSpeechInput } from '../hooks/useSpeechInput'
import { parseOrderList } from '../lib/parseOrder'
import type { ParsedOrder } from '../types/order'
import { MicButton } from './MicButton'

type Props = {
  initialText?: string
  resetButton?: ReactNode
  onParsed: (items: ParsedOrder[], spoken: string) => void
  onSkip: () => void
}

export function OpeningCapture({ initialText = '', resetButton, onParsed, onSkip }: Props) {
  const [text, setText] = useState(initialText)
  const [error, setError] = useState('')
  const spokenRef = useRef(initialText)

  const speech = useSpeechInput({
    onPreview: (preview) => {
      const shown = spokenRef.current ? `${spokenRef.current} ${preview}` : preview
      setText(shown)
      setError('')
    },
    onFinal: (finalText) => {
      spokenRef.current = spokenRef.current ? `${spokenRef.current} ${finalText}` : finalText
      setText(spokenRef.current)
    },
  })

  const submit = (raw: string) => {
    const items = parseOrderList(raw)
    if (items.length === 0) {
      setError('商品名と金額が読み取れませんでした。例: ビール2つ650円、カルビ3つ880円')
      return
    }
    onParsed(items, raw)
  }

  const finishVoice = () => {
    speech.stop()
    const raw = text.trim()
    if (!raw) {
      setError('話してから、できたを押してください')
      return
    }
    submit(raw)
  }

  return (
    <div className="mx-auto flex h-dvh w-full max-w-3xl flex-col overflow-hidden bg-bg pt-safe pb-safe">
      <header className="relative shrink-0 px-4 pt-6 text-center">
        {resetButton}
        <h1 className="px-16 text-2xl font-bold tracking-wide sm:text-3xl">今いくら頼んだ？</h1>
        <p className="mt-2 text-sm text-muted">
          最初はまとめて言ってください。あとから直せます。
        </p>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto px-4 py-4">
        <textarea
          value={text}
          readOnly={speech.listening}
          onChange={(event) => {
            spokenRef.current = event.target.value
            setText(event.target.value)
            if (error) setError('')
          }}
          placeholder={'ビール2つ650円、カルビ3つ880円、餃子1100円を2つ'}
          aria-label="まとめて注文"
          className={`min-h-40 w-full resize-none rounded-2xl border bg-card px-4 py-3 text-base leading-relaxed ${
            speech.listening ? 'border-gold' : 'border-line'
          }`}
        />
        {speech.listening ? (
          <p className="mt-2 text-sm text-gold">聞いています。全部言い終わったらできたを押してください。</p>
        ) : (
          <p className="mt-2 text-sm text-muted">「何がいくつ、いくら」を続けてどうぞ。</p>
        )}
        {error ? <p className="mt-2 text-sm text-danger">{error || speech.error}</p> : null}
        {speech.error && !error ? <p className="mt-2 text-sm text-danger">{speech.error}</p> : null}
      </div>

      <div className="shrink-0 space-y-2 border-t border-line px-4 pt-3 pb-3">
        <div className="flex gap-2">
          {speech.available && (
            <MicButton
              listening={speech.listening}
              onToggle={speech.listening ? speech.stop : speech.start}
            />
          )}
          <button
            type="button"
            className="h-14 flex-1 rounded-2xl bg-gold text-lg font-bold text-bg"
            onClick={() => {
              if (speech.listening) finishVoice()
              else submit(text)
            }}
          >
            {speech.listening ? 'できた' : '読み取る'}
          </button>
        </div>
        <button type="button" className="h-11 w-full text-sm text-muted underline" onClick={onSkip}>
          1品ずつ入れる
        </button>
      </div>
    </div>
  )
}
