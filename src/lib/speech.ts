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
  recognition.continuous = false

  recognition.onresult = (event: SpeechRecognitionEvent) => {
    let preview = ''
    let finalText = ''
    for (let i = event.resultIndex; i < event.results.length; i += 1) {
      const result = event.results[i]
      const transcript = result[0]?.transcript ?? ''
      if (result.isFinal) finalText += transcript
      else preview += transcript
    }
    if (preview) handlers.onPreview(preview)
    if (finalText) handlers.onFinal(finalText.trim())
  }

  recognition.onerror = (event: SpeechRecognitionErrorEvent) => {
    if (event.error === 'aborted' || event.error === 'no-speech') {
      handlers.onEnd()
      return
    }
    if (event.error === 'not-allowed') {
      handlers.onError('マイクの使用が許可されていません')
    } else {
      handlers.onError('音声を認識できませんでした')
    }
    handlers.onEnd()
  }

  recognition.onend = () => {
    handlers.onEnd()
  }

  recognition.start()

  return () => {
    recognition.onresult = null
    recognition.onerror = null
    recognition.onend = null
    recognition.abort()
  }
}
