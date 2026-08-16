import { useEffect, useRef, useState } from 'react'
import { parseOrderText } from '../lib/parseOrder'
import { isSpeechAvailable, startListening } from '../lib/speech'
import type { NewOrder, ParsedOrder } from '../types/order'
import { ConfirmCard } from './ConfirmCard'
import { ManualForm } from './ManualForm'

type Mode = 'quick' | 'confirm' | 'manual'

type Props = {
  onAdd: (item: NewOrder) => void
}

export function AddOrder({ onAdd }: Props) {
  const [text, setText] = useState('')
  const [mode, setMode] = useState<Mode>('quick')
  const [parsed, setParsed] = useState<ParsedOrder | null>(null)
  const [listening, setListening] = useState(false)
  const [error, setError] = useState('')
  const [fromVoice, setFromVoice] = useState(false)
  const stopRef = useRef<(() => void) | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const speechOk = isSpeechAvailable()

  useEffect(() => {
    return () => stopRef.current?.()
  }, [])

  const resetQuick = () => {
    setMode('quick')
    setParsed(null)
    setText('')
    setError('')
    setFromVoice(false)
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
      setError('商品名と金額を入力してください。例: ビール650円を2つ')
      return
    }
    setError('')
    if (fromVoice || !result.name) {
      setParsed(result)
      setMode(result.name ? 'confirm' : 'manual')
      return
    }
    addParsed(result)
  }

  const startMic = () => {
    setError('')
    setFromVoice(true)
    setListening(true)
    stopRef.current = startListening({
      onPreview: (preview) => setText(preview),
      onFinal: (finalText) => {
        setText(finalText)
        const result = parseOrderText(finalText)
        if (!result) {
          setError('聞き取れました。金額を含めて修正してください')
          setMode('quick')
          return
        }
        setParsed(result)
        setMode(result.name ? 'confirm' : 'manual')
      },
      onError: (message) => setError(message),
      onEnd: () => {
        setListening(false)
        stopRef.current = null
      },
    })
  }

  const stopMic = () => {
    stopRef.current?.()
    stopRef.current = null
    setListening(false)
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
                ref={inputRef}
                value={text}
                onChange={(event) => {
                  setText(event.target.value)
                  if (error) setError('')
                }}
                placeholder="ビール650円を2つ"
                aria-label="注文"
                enterKeyHint="done"
                autoCapitalize="none"
                autoComplete="off"
                className="h-14 min-w-0 flex-1 rounded-2xl border border-line bg-card px-4 text-base"
              />
              {speechOk && (
                <button
                  type="button"
                  aria-label={listening ? '音声入力を止める' : '音声で入力'}
                  className={`flex size-14 shrink-0 items-center justify-center rounded-2xl border text-xl ${
                    listening
                      ? 'border-gold bg-gold text-bg'
                      : 'border-line bg-card text-gold'
                  }`}
                  onClick={listening ? stopMic : startMic}
                >
                  {listening ? '■' : '🎤'}
                </button>
              )}
            </div>
            {listening ? (
              <p className="text-sm text-gold">聞いています。話してから少し待つと文字になります。</p>
            ) : null}
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
