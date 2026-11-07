import { useEffect, useRef, useState } from 'react'
import { searchNearbyPlaces, type PlaceCandidate } from '../lib/places'

type Props = {
  value: string | null
  onChange: (placeName: string | null) => void
  autoSearch?: boolean
}

type Status = 'idle' | 'loading' | 'ready' | 'error'

export function PlacePicker({ value, onChange, autoSearch = true }: Props) {
  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState('')
  const [candidates, setCandidates] = useState<PlaceCandidate[]>([])
  const [draft, setDraft] = useState(value ?? '')
  const valueRef = useRef(value)
  valueRef.current = value
  const onChangeRef = useRef(onChange)
  onChangeRef.current = onChange
  const abortRef = useRef<AbortController | null>(null)

  useEffect(() => {
    setDraft(value ?? '')
  }, [value])

  useEffect(() => {
    return () => {
      abortRef.current?.abort()
    }
  }, [])

  const runSearch = async () => {
    abortRef.current?.abort()
    const controller = new AbortController()
    abortRef.current = controller
    setStatus('loading')
    setError('')
    try {
      const nearby = await searchNearbyPlaces(controller.signal)
      if (controller.signal.aborted) return
      setCandidates(nearby)
      setStatus('ready')
      if (!valueRef.current && nearby[0]) {
        onChangeRef.current(nearby[0].name)
        setDraft(nearby[0].name)
      }
    } catch (err) {
      if (controller.signal.aborted) return
      setCandidates([])
      setStatus('error')
      setError(err instanceof Error ? err.message : '近くの店を探せませんでした')
    }
  }

  useEffect(() => {
    if (!autoSearch) return
    void runSearch()
    // eslint-disable-next-line react-hooks/exhaustive-deps -- search once on mount
  }, [autoSearch])

  const applyDraft = () => {
    const trimmed = draft.trim()
    onChange(trimmed ? trimmed : null)
  }

  return (
    <section className="rounded-2xl border border-line bg-card p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="font-semibold">お店の名前</p>
          <p className="mt-0.5 text-sm text-muted">現在地から候補を出します。違ったら直せます。</p>
        </div>
        <button
          type="button"
          className="shrink-0 text-sm text-muted underline disabled:opacity-40"
          disabled={status === 'loading'}
          onClick={() => {
            void runSearch()
          }}
        >
          {status === 'loading' ? '検索中…' : '再検索'}
        </button>
      </div>

      {status === 'loading' ? (
        <p className="mt-3 text-sm text-gold">位置情報で近くの店を探しています…</p>
      ) : null}
      {error ? <p className="mt-3 text-sm text-danger">{error}</p> : null}

      {candidates.length > 0 ? (
        <ul className="mt-3 space-y-2">
          {candidates.map((place) => {
            const selected = value === place.name
            return (
              <li key={place.id}>
                <button
                  type="button"
                  className={`flex w-full items-center justify-between gap-3 rounded-xl border px-3 py-3 text-left ${
                    selected ? 'border-gold bg-surface' : 'border-line bg-surface/50'
                  }`}
                  onClick={() => {
                    onChange(place.name)
                    setDraft(place.name)
                  }}
                >
                  <span className="font-semibold leading-tight">{place.name}</span>
                  <span className="shrink-0 text-sm text-muted tabular-nums">
                    {place.distanceM}m
                  </span>
                </button>
              </li>
            )
          })}
        </ul>
      ) : null}

      <label className="mt-3 block">
        <span className="text-sm text-muted">手入力</span>
        <input
          value={draft}
          onChange={(event) => setDraft(event.target.value)}
          onBlur={applyDraft}
          onKeyDown={(event) => {
            if (event.key === 'Enter') {
              event.preventDefault()
              applyDraft()
              ;(event.target as HTMLInputElement).blur()
            }
          }}
          placeholder="例: ○○焼肉"
          className="mt-1 h-12 w-full rounded-xl border border-line bg-surface px-3"
          autoComplete="off"
        />
      </label>
    </section>
  )
}
