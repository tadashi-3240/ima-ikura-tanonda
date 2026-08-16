export function isSpeechAvailable(): boolean {
  return (
    typeof window !== 'undefined' &&
    Boolean(window.SpeechRecognition || window.webkitSpeechRecognition)
  )
}

type ListenHandlers = {
  onPreview: (text: string) => void
  onFinal: (text: string) => void
  onError: (message: string) => void
  onEnd: () => void
}

export function startListening(handlers: ListenHandlers): () => void {
  const Ctor = window.SpeechRecognition || window.webkitSpeechRecognition
  if (!Ctor) {
    handlers.onError('このブラウザでは音声入力に対応していません')
    handlers.onEnd()
    return () => {}
  }

  const recognition = new Ctor()
  recognition.lang = 'ja-JP'
  recognition.interimResults = true
  recognition.continuous = true
  recognition.maxAlternatives = 1

  let stopped = false
  let silenceTimer: ReturnType<typeof setTimeout> | null = null
  let lastFinal = ''
  let consumed = 0

  const clearSilence = () => {
    if (silenceTimer) {
      clearTimeout(silenceTimer)
      silenceTimer = null
    }
  }

  const finish = () => {
    if (stopped) return
    stopped = true
    clearSilence()
    try {
      recognition.stop()
    } catch {
      /* already stopped */
    }
  }

  const commitUtterance = (resultCount: number) => {
    consumed = resultCount
    const text = lastFinal.trim()
    lastFinal = ''
    if (text) handlers.onFinal(text)
  }

  recognition.onresult = (event: SpeechRecognitionEvent) => {
    let preview = ''
    let finalText = ''
    for (let i = consumed; i < event.results.length; i += 1) {
      const result = event.results[i]
      const transcript = result[0]?.transcript ?? ''
      if (result.isFinal) finalText += transcript
      else preview += transcript
    }
    const shown = `${finalText}${preview}`.trim()
    if (shown) handlers.onPreview(shown)
    if (finalText.trim()) {
      lastFinal = finalText.trim()
      clearSilence()
      silenceTimer = setTimeout(() => commitUtterance(event.results.length), 1200)
    }
  }

  recognition.onerror = (event: SpeechRecognitionErrorEvent) => {
    if (event.error === 'aborted' || event.error === 'no-speech') {
      return
    }
    if (event.error === 'not-allowed') {
      handlers.onError('マイクの使用が許可されていません。ブラウザの設定を確認してください')
    } else if (event.error === 'network') {
      handlers.onError('音声認識の通信に失敗しました')
    } else {
      handlers.onError('音声を認識できませんでした')
    }
    finish()
  }

  recognition.onend = () => {
    clearSilence()
    if (!stopped) {
      consumed = 0
      lastFinal = ''
      try {
        recognition.start()
        return
      } catch {
        stopped = true
      }
    }
    const text = lastFinal.trim()
    if (text) handlers.onFinal(text)
    handlers.onEnd()
  }

  try {
    recognition.start()
  } catch {
    handlers.onError('音声入力を開始できませんでした')
    handlers.onEnd()
    return () => {}
  }

  return () => {
    finish()
  }
}
