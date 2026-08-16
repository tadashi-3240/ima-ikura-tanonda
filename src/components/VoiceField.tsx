import { useLayoutEffect, useRef, useState, type InputHTMLAttributes } from 'react'

type Props = Omit<InputHTMLAttributes<HTMLInputElement>, 'value'> & {
  value: string
  showCaret?: boolean
  padClass?: string
  padPx?: number
}

export function VoiceField({
  value,
  showCaret = false,
  padClass = 'px-4',
  padPx = 16,
  className = '',
  ...props
}: Props) {
  const boxRef = useRef<HTMLDivElement>(null)
  const textRef = useRef<HTMLSpanElement>(null)
  const [caretLeft, setCaretLeft] = useState(padPx)

  useLayoutEffect(() => {
    if (!showCaret) return
    const box = boxRef.current
    const measure = textRef.current
    if (!box || !measure) return
    const max = Math.max(padPx, box.clientWidth - padPx - 4)
    setCaretLeft(Math.min(padPx + measure.offsetWidth, max))
  }, [showCaret, value, padPx])

  return (
    <div ref={boxRef} className="relative min-w-0 flex-1">
      <input
        value={value}
        className={`w-full caret-transparent ${padClass} ${className}`}
        {...props}
      />
      <span
        ref={textRef}
        className="pointer-events-none invisible absolute top-0 whitespace-pre text-base"
        style={{ left: padPx }}
        aria-hidden
      >
        {value}
      </span>
      {showCaret ? (
        <span
          aria-hidden
          className="animate-caret pointer-events-none absolute top-1/2 h-8 w-1 -translate-y-1/2 rounded-sm bg-gold"
          style={{ left: caretLeft }}
        />
      ) : null}
    </div>
  )
}
