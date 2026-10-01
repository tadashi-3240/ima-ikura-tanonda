import { useEffect, useId, useRef, useState, type FormEvent } from 'react'
import { COLOR_ORDER, EVENT_COLORS, type EventForm } from './types'

type Props = {
  title: string
  description?: string
  initial: EventForm
  onClose: () => void
  onSubmit: (form: EventForm) => string | null
  onDelete?: () => void
}

const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]), textarea:not([disabled]), select:not([disabled])'

function focusableElements(root: HTMLElement): HTMLElement[] {
  return [...root.querySelectorAll<HTMLElement>(FOCUSABLE)].filter(
    (element) => !element.closest('[hidden]') && element.getClientRects().length > 0,
  )
}

export function EventDialog({
  title,
  description,
  initial,
  onClose,
  onSubmit,
  onDelete,
}: Props) {
  const titleId = useId()
  const dialogRef = useRef<HTMLDivElement>(null)
  const onCloseRef = useRef(onClose)
  const [form, setForm] = useState(initial)
  const [error, setError] = useState<string | null>(null)
  const [confirmingDelete, setConfirmingDelete] = useState(false)
  onCloseRef.current = onClose

  useEffect(() => {
    const dialog = dialogRef.current
    if (!dialog) return
    const previouslyFocused = document.activeElement
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'

    const focusFirst = () => {
      const titleInput = dialog.querySelector<HTMLElement>('#event-title')
      const items = focusableElements(dialog)
      ;(titleInput ?? items[0])?.focus()
    }
    focusFirst()

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault()
        onCloseRef.current()
        return
      }
      if (event.key !== 'Tab') return
      const items = focusableElements(dialog)
      if (items.length === 0) return
      const first = items[0]
      const last = items[items.length - 1]
      const active = document.activeElement
      if (event.shiftKey && (active === first || !dialog.contains(active))) {
        event.preventDefault()
        last.focus()
      } else if (!event.shiftKey && active === last) {
        event.preventDefault()
        first.focus()
      }
    }

    document.addEventListener('keydown', onKeyDown)
    return () => {
      document.removeEventListener('keydown', onKeyDown)
      document.body.style.overflow = previousOverflow
      if (previouslyFocused instanceof HTMLElement) previouslyFocused.focus()
    }
  }, [])

  const update = (patch: Partial<EventForm>) => {
    setForm((current) => ({ ...current, ...patch }))
    setError(null)
  }

  const submit = (event: FormEvent) => {
    event.preventDefault()
    const message = onSubmit(form)
    if (message) setError(message)
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-[#243038]/40 p-0 sm:items-center sm:p-6"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose()
      }}
    >
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="max-h-[92dvh] w-full overflow-y-auto rounded-t-3xl border border-line bg-surface p-5 shadow-xl sm:max-w-lg sm:rounded-3xl"
      >
        <div className="flex items-start justify-between gap-3">
          <div>
            <h2 id={titleId} className="text-xl font-bold">
              {title}
            </h2>
            {description ? <p className="mt-1 text-sm text-muted">{description}</p> : null}
          </div>
          <button
            type="button"
            className="h-11 rounded-xl px-3 text-sm text-muted"
            onClick={onClose}
          >
            閉じる
          </button>
        </div>

        <form className="mt-4 space-y-4" onSubmit={submit} noValidate>
          <div>
            <label htmlFor="event-title" className="text-sm font-semibold">
              タイトル
            </label>
            <input
              id="event-title"
              value={form.title}
              onChange={(event) => update({ title: event.target.value })}
              placeholder="予定のタイトル"
              autoComplete="off"
              className="mt-1 h-12 w-full rounded-xl border border-line bg-bg px-3 text-base"
            />
          </div>

          <label className="flex min-h-11 items-center gap-3 text-sm font-semibold">
            <input
              type="checkbox"
              className="size-5 accent-accent"
              checked={form.allDay}
              onChange={(event) => update({ allDay: event.target.checked })}
            />
            終日
          </label>

          <div className="grid gap-3 sm:grid-cols-2">
            <fieldset className="min-w-0 rounded-xl border border-line p-3">
              <legend className="px-1 text-sm font-semibold">開始</legend>
              <input
                aria-label="開始日"
                type="date"
                value={form.startDate}
                onChange={(event) => update({ startDate: event.target.value })}
                className="mt-1 h-11 w-full rounded-lg border border-line bg-bg px-2 text-base"
              />
              {form.allDay ? null : (
                <input
                  aria-label="開始時刻"
                  type="time"
                  value={form.startTime}
                  onChange={(event) => update({ startTime: event.target.value })}
                  className="mt-2 h-11 w-full rounded-lg border border-line bg-bg px-2 text-base"
                />
              )}
            </fieldset>
            <fieldset className="min-w-0 rounded-xl border border-line p-3">
              <legend className="px-1 text-sm font-semibold">終了</legend>
              <input
                aria-label="終了日"
                type="date"
                value={form.endDate}
                onChange={(event) => update({ endDate: event.target.value })}
                className="mt-1 h-11 w-full rounded-lg border border-line bg-bg px-2 text-base"
              />
              {form.allDay ? null : (
                <input
                  aria-label="終了時刻"
                  type="time"
                  value={form.endTime}
                  onChange={(event) => update({ endTime: event.target.value })}
                  className="mt-2 h-11 w-full rounded-lg border border-line bg-bg px-2 text-base"
                />
              )}
            </fieldset>
          </div>

          <fieldset>
            <legend className="text-sm font-semibold">色</legend>
            <div className="mt-2 flex flex-wrap gap-2">
              {COLOR_ORDER.map((color) => {
                const swatch = EVENT_COLORS[color]
                const selected = form.color === color
                return (
                  <label
                    key={color}
                    className={`inline-flex size-11 cursor-pointer items-center justify-center rounded-full focus-within:ring-2 focus-within:ring-accent ${
                      selected ? 'ring-2 ring-accent ring-offset-2 ring-offset-surface' : ''
                    }`}
                  >
                    <input
                      type="radio"
                      name="event-color"
                      className="sr-only"
                      checked={selected}
                      onChange={() => update({ color })}
                    />
                    <span
                      className="size-7 rounded-full"
                      style={{ background: swatch.bar }}
                      aria-hidden="true"
                    />
                    <span className="sr-only">{swatch.label}</span>
                  </label>
                )
              })}
            </div>
          </fieldset>

          <div>
            <label htmlFor="event-location" className="text-sm font-semibold">
              場所（任意）
            </label>
            <input
              id="event-location"
              value={form.location}
              onChange={(event) => update({ location: event.target.value })}
              className="mt-1 h-12 w-full rounded-xl border border-line bg-bg px-3 text-base"
            />
          </div>

          <div>
            <label htmlFor="event-notes" className="text-sm font-semibold">
              メモ（任意）
            </label>
            <textarea
              id="event-notes"
              value={form.notes}
              rows={3}
              onChange={(event) => update({ notes: event.target.value })}
              className="mt-1 w-full resize-y rounded-xl border border-line bg-bg px-3 py-2 text-base"
            />
          </div>

          {error ? (
            <p role="alert" className="text-sm font-semibold text-danger">
              {error}
            </p>
          ) : null}

          {confirmingDelete ? (
            <div className="rounded-2xl bg-bg p-3">
              <p className="text-sm font-semibold">この予定を削除しますか？</p>
              <div className="mt-3 flex flex-col gap-2 sm:flex-row">
                <button
                  type="button"
                  className="h-11 flex-1 rounded-xl bg-danger font-semibold text-white"
                  onClick={onDelete}
                >
                  削除する
                </button>
                <button
                  type="button"
                  className="h-11 flex-1 rounded-xl border border-line bg-surface"
                  onClick={() => setConfirmingDelete(false)}
                >
                  戻る
                </button>
              </div>
            </div>
          ) : (
            <div className="flex flex-col gap-2 sm:flex-row">
              <button
                type="submit"
                className="h-11 flex-1 rounded-xl bg-accent font-semibold text-white"
              >
                保存する
              </button>
              {onDelete ? (
                <button
                  type="button"
                  className="h-11 rounded-xl border border-line px-4 text-danger"
                  onClick={() => setConfirmingDelete(true)}
                >
                  削除
                </button>
              ) : null}
              <button
                type="button"
                className="h-11 rounded-xl border border-line px-4"
                onClick={onClose}
              >
                キャンセル
              </button>
            </div>
          )}
        </form>
      </div>
    </div>
  )
}
