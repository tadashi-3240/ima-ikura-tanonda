import { useState } from 'react'
import { useSpeechInput } from '../hooks/useSpeechInput'
import { parseOrderText } from '../lib/parseOrder'
import type { NewOrder, ParsedOrder } from '../types/order'
import { ConfirmCard } from './ConfirmCard'
import { ManualForm } from './ManualForm'
import { MicButton } from './MicButton'

type Mode = 'quick' | 'confirm' | 'manual'

type Props = {
  onAdd: (item: NewOrder) => void
}

export function AddOrder({ onAdd }: Props) {
  const [text, setText] = useState('')
  const [mode, setMode] = useState<Mode>('quick')
  const [parsed, setParsed] = useState<ParsedOrder | null>(null)
  const [fromVoice, setFromVoice] = useState(false)

  const speech = useSpeechInput({
    onPreview: (preview) => setText(preview),
    onFinal: (finalText) => {
      setText(finalText)
      const result = parseOrderText(finalText)
      if (!result) {
        speech.setError('聞き取れました。金額を含めて修正してください')
        setMode('quick')
        return
      }
      setParsed(result)
      setMode(result.name ? 'confirm' : 'manual')
    },
  })

  const resetQuick = () => {
    setMode('quick')
    setParsed(null)
    setText('')
    setFromVoice(false)
    speech.setError('')
    speech.stop()
  }

  const addParsed = (item: ParsedOrder) => {
    if (!item.name) {
      setParsed(item)
      setMode('manual')
      return
    }
    onAdd(item)
    resetQuick()
  }

  const submitText = () => {
    const result = parseOrderText(text)
    if (!result) {
      speech.setError('商品名と金額を入力してください。例: ビール650円を2つ')
      return
    }
    speech.setError('')
    if (fromVoice || !result.name) {
      setParsed(result)
      setMode(result.name ? 'confirm' : 'manual')
      return
    }
    addParsed(result)
  }

  const startMic = () => {
    setFromVoice(true)
    speech.start()
  }

  return (
    <div className="fixed inset-x-0 bottom-0 z-30 border-t border-line bg-bg/95 px-3 pt-3 pb-safe backdrop-blur-md">
      {mode === 'confirm' && parsed && (
        <ConfirmCard
          parsed={parsed}
          onAdd={() => addParsed(parsed)}
          onEdit={() => setMode('manual')}
        />
      )}

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
            <div className="flex items-center gap-2">
              <input
                value={text}
                readOnly={speech.listening}
                inputMode={speech.listening ? 'none' : 'text'}
                onChange={(event) => {
                  setText(event.target.value)
                  if (speech.error) speech.setError('')
                }}
                placeholder="ビール650円を2つ"
                aria-label="注文"
                enterKeyHint="done"
                autoCapitalize="none"
                autoComplete="off"
                className={`h-14 min-w-0 flex-1 rounded-2xl border bg-card px-4 text-base ${
                  speech.listening ? 'border-gold' : 'border-line'
                }`}
              />
              {speech.available && (
                <MicButton
                  listening={speech.listening}
                  onToggle={speech.listening ? speech.stop : startMic}
                />
              )}
            </div>
            {speech.listening ? (
              <p className="text-sm text-gold">聞いています。話してください。</p>
            ) : null}
            <button
              type="submit"
              className="h-14 w-full rounded-2xl bg-gold text-lg font-bold text-bg"
            >
              追加
            </button>
          </form>
          <div className="mt-2 flex items-center justify-between gap-3">
            <p className="min-h-5 text-sm text-danger">{speech.error}</p>
            <button
              type="button"
              className="text-sm text-muted underline"
              onClick={() => {
                speech.stop()
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
