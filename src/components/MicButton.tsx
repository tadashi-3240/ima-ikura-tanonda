type Props = {
  listening: boolean
  onToggle: () => void
}

export function MicButton({ listening, onToggle }: Props) {
  return (
    <button
      type="button"
      aria-label={listening ? '音声入力を止める' : '音声で入力'}
      className={`flex size-14 shrink-0 items-center justify-center rounded-2xl border text-xl ${
        listening ? 'border-gold bg-gold text-bg' : 'border-line bg-card text-gold'
      }`}
      onClick={onToggle}
    >
      {listening ? '■' : '🎤'}
    </button>
  )
}
