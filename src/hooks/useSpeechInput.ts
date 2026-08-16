import { useCallback, useEffect, useRef, useState } from 'react'
import { isSpeechAvailable, startListening } from '../lib/speech'

type Handlers = {
  onPreview?: (text: string) => void
  onFinal: (text: string) => void
}

export function useSpeechInput(handlers: Handlers) {
  const [listening, setListening] = useState(false)
  const [error, setError] = useState('')
  const stopRef = useRef<(() => void) | null>(null)
  const handlersRef = useRef(handlers)
  handlersRef.current = handlers

  useEffect(() => {
    return () => stopRef.current?.()
  }, [])

  const stop = useCallback(() => {
    stopRef.current?.()
    stopRef.current = null
    setListening(false)
  }, [])

  const start = useCallback(() => {
    setError('')
    setListening(true)
    stopRef.current = startListening({
      onPreview: (text) => handlersRef.current.onPreview?.(text),
      onFinal: (text) => handlersRef.current.onFinal(text),
      onError: setError,
      onEnd: () => {
        setListening(false)
        stopRef.current = null
      },
    })
    if (document.activeElement instanceof HTMLElement) {
      document.activeElement.blur()
    }
  }, [])

  return {
    available: isSpeechAvailable(),
    listening,
    error,
    setError,
    start,
    stop,
    toggle: listening ? stop : start,
  }
}
