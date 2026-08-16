import { useRef, useState } from 'react'
import { useSpeechInput } from '../hooks/useSpeechInput'
import { parseOrderText } from '../lib/parseOrder'
import type { NewOrder, ParsedOrder } from '../types/order'
import { ManualForm } from './ManualForm'
import { MicButton } from './MicButton'
import { VoiceField } from './VoiceField'

type Mode = 'quick' | 'manual'

type Props = {
  onAdd: (item: NewOrder) => void
}

export function AddOrder({ onAdd }: Props) {
  const [text, setText] = useState('')
  const [mode, setMode] = useState<Mode>('quick')
  const [parsed, setParsed] = useState<ParsedOrder | null>(null)
  const [fromVoice, setFromVoice] = useState(false)
  const modeRef = useRef(mode)
  const skipDuplicateFinalRef = useRef(false)
  modeRef.current = mode

  const speech = useSpeechInput({
    onPreview: (preview) => {
      if (modeRef.current !== 'quick') return
      skipDuplicateFinalRef.current = false
      setText(preview)
    },
    onFinal: (finalText) => {
      if (modeRef.current !== 'quick') return
      if (skipDuplicateFinalRef.current) return
      setText(finalText)
      const result = parseOrderText(finalText)
      if (!result) {
        speech.setError('聞き取れました。金額を含めて修正してください')
        return
      }
      if (!result.name) {
        speech.stop()
        setParsed(result)
        setMode('manual')
        return
      }
      skipDuplicateFinalRef.current = true
      onAdd(result)
      setText('')
      speech.setError('')
    },
  })

  const resetQuick = (continueListening = false) => {
    setMode('quick')
    setParsed(null)
    setText('')
    speech.setError('')
    if (continueListening) {
      setFromVoice(true)
      if (!speech.listening) speech.start()
    } else {
      setFromVoice(false)
      speech.stop()
    }
  }

  const addParsed = (item: ParsedOrder) => {
    if (!item.name) {
      speech.stop()
      setParsed(item)
      setMode('manual')
      return
    }
    onAdd(item)
    resetQuick(fromVoice)
  }

  const submitText = () => {
    const result = parseOrderText(text)
    if (!result) {
      speech.setError('商品名と金額を入力してください。例: ビール650円を2つ')
      return
    }
    speech.setError('')
    addParsed(result)
  }

  const startMic = () => {
    setFromVoice(true)
    skipDuplicateFinalRef.current = false
    speech.start()
  }

  const stopMic = () => {
    setFromVoice(false)
    speech.stop()
  }

  return (
    <div className="fixed inset-x-0 bottom-0 z-30 border-t border-line bg-bg/95 px-3 pt-3 pb-safe backdrop-blur-md">
      {mode === 'manual' && (
        <div className="rounded-2xl border border-line bg-card p-4">
          <p className="mb-3 font-semibold">手入力</p>
          <ManualForm
            initial={parsed ?? { quantity: 1 }}
            onSubmit={(item) => {
              onAdd(item)
              resetQuick(fromVoice)
            }}
            onCancel={() => resetQuick(false)}
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
              <VoiceField
                value={text}
                showCaret={speech.listening}
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
                className={`h-14 rounded-2xl border bg-card text-base ${
                  speech.listening ? 'border-gold' : 'border-line'
                }`}
              />
              {speech.available && (
                <MicButton
                  listening={speech.listening}
                  onToggle={speech.listening ? stopMic : startMic}
                />
              )}
            </div>
            {speech.listening ? (
              <p className="text-sm text-gold">聞いています。通ったらすぐ追加します。</p>
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
                setFromVoice(false)
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
