import { useEffect, useMemo, useState } from 'react'
import {
  addDays,
  addMonths,
  monthCells,
  rangeLabel,
  tokyoToday,
  weekDays,
  type Ymd,
} from './dates'
import { EventDialog } from './EventDialog'
import { draftForSlot, eventToForm, eventsOnDay, formToEvent } from './model'
import { MonthView } from './MonthView'
import { TimeGrid } from './TimeGrid'
import type { CalendarEvent, CalendarView, EventForm } from './types'
import { useEvents } from './useEvents'

type DialogState =
  | { mode: 'create'; form: EventForm }
  | { mode: 'edit'; event: CalendarEvent }
  | null

const VIEW_LABEL: Record<CalendarView, { short: string; name: string }> = {
  month: { short: '月', name: '月表示' },
  week: { short: '週', name: '週表示' },
  day: { short: '日', name: '日表示' },
}

function shiftCursor(cursor: Ymd, view: CalendarView, delta: number): Ymd {
  if (view === 'month') return addMonths(cursor, delta)
  if (view === 'week') return addDays(cursor, delta * 7)
  return addDays(cursor, delta)
}

function stepLabel(view: CalendarView, direction: 'prev' | 'next'): string {
  const map = {
    month: ['前月', '次月'],
    week: ['前週', '次週'],
    day: ['前日', '次日'],
  } as const
  return map[view][direction === 'prev' ? 0 : 1]
}

export function CalendarApp() {
  const { events, upsert, remove } = useEvents()
  const [now, setNow] = useState(() => new Date())
  const [view, setView] = useState<CalendarView>('month')
  const [cursor, setCursor] = useState<Ymd>(() => tokyoToday())
  const [dialog, setDialog] = useState<DialogState>(null)

  useEffect(() => {
    const id = window.setInterval(() => setNow(new Date()), 60_000)
    return () => window.clearInterval(id)
  }, [])

  const today = useMemo(() => tokyoToday(now), [now])
  const label = rangeLabel(view, cursor)

  useEffect(() => {
    document.title = `${label} · カレンダー`
  }, [label])

  const cells = monthCells(cursor.year, cursor.month)
  const week = weekDays(cursor)
  const visibleDays = view === 'month' ? cells : view === 'week' ? week : [cursor]
  const rangeEmpty = visibleDays.every((day) => eventsOnDay(events, day).length === 0)
  const hasSamples = events.some((event) => event.sample)

  const openCreate = (day: Ymd, hour = 9) => {
    setCursor(day)
    setDialog({ mode: 'create', form: draftForSlot(day, hour) })
  }

  const submitForm = (form: EventForm): string | null => {
    if (!dialog) return null
    const id = dialog.mode === 'edit' ? dialog.event.id : crypto.randomUUID()
    const sample =
      dialog.mode === 'edit' && dialog.event.sample && form.title.includes('サンプル')
    const result = formToEvent(form, id, sample)
    if (!result.ok) return result.message
    upsert(result.event)
    setDialog(null)
    return null
  }

  const emptyCopy =
    view === 'month'
      ? 'この月の予定はありません'
      : view === 'week'
        ? 'この週の予定はありません'
        : 'この日の予定はありません'

  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-6xl flex-col px-3 pt-safe sm:px-6">
      <header className="sticky top-0 z-30 -mx-3 border-b border-line bg-bg px-3 pb-3 sm:-mx-6 sm:px-6">
        <div className="flex items-end justify-between gap-3 pt-3">
          <div>
            <p className="text-xs font-semibold tracking-widest text-accent">個人用</p>
            <h1 className="text-2xl font-bold tracking-tight">カレンダー</h1>
          </div>
          <button
            type="button"
            className="h-11 rounded-xl border border-line bg-surface px-4 text-sm font-semibold"
            onClick={() => setCursor(today)}
          >
            今日
          </button>
        </div>

        <div className="mt-3 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex items-center gap-2">
            <button
              type="button"
              className="h-11 shrink-0 rounded-xl border border-line bg-surface px-3 text-sm"
              onClick={() => setCursor((current) => shiftCursor(current, view, -1))}
            >
              {stepLabel(view, 'prev')}
            </button>
            <h2 aria-live="polite" className="min-w-0 flex-1 text-center text-lg font-bold lg:text-left">
              {label}
            </h2>
            <button
              type="button"
              className="h-11 shrink-0 rounded-xl border border-line bg-surface px-3 text-sm"
              onClick={() => setCursor((current) => shiftCursor(current, view, 1))}
            >
              {stepLabel(view, 'next')}
            </button>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <div role="tablist" aria-label="表示" className="flex rounded-xl bg-[#e7e1d6] p-1">
              {(Object.keys(VIEW_LABEL) as CalendarView[]).map((item) => (
                <button
                  key={item}
                  type="button"
                  role="tab"
                  aria-selected={view === item}
                  aria-label={VIEW_LABEL[item].name}
                  className={`h-10 min-w-11 rounded-lg px-3 text-sm font-semibold ${
                    view === item ? 'bg-surface text-ink shadow-sm' : 'text-muted'
                  }`}
                  onClick={() => setView(item)}
                >
                  {VIEW_LABEL[item].short}
                </button>
              ))}
            </div>
            <button
              type="button"
              className="h-11 rounded-xl bg-accent px-4 text-sm font-semibold text-white"
              onClick={() => openCreate(cursor)}
            >
              予定を追加
            </button>
          </div>
        </div>
      </header>

      <main className="flex-1 py-4">
        {hasSamples ? (
          <p className="mb-3 rounded-2xl border border-line bg-accent-soft px-4 py-3 text-sm text-ink">
            「サンプル」の予定は見本です。編集や削除ができます。
          </p>
        ) : null}

        {events.length === 0 ? (
          <p className="mb-3 rounded-2xl border border-dashed border-line bg-surface px-4 py-6 text-center text-sm text-muted">
            予定はまだありません。「予定を追加」から作成できます。
          </p>
        ) : rangeEmpty ? (
          <p className="mb-3 text-sm text-muted">{emptyCopy}</p>
        ) : null}

        {view === 'month' ? (
          <MonthView
            cells={cells}
            month={cursor.month}
            cursor={cursor}
            today={today}
            events={events}
            onSelectDay={setCursor}
            onSelectEvent={(event) => setDialog({ mode: 'edit', event })}
            onCreate={(day) => openCreate(day)}
          />
        ) : (
          <TimeGrid
            days={view === 'week' ? week : [cursor]}
            today={today}
            now={now}
            events={events}
            onOpenDay={(day) => {
              setCursor(day)
              setView('day')
            }}
            onSelectEvent={(event) => setDialog({ mode: 'edit', event })}
            onCreateAt={openCreate}
          />
        )}
      </main>

      <footer className="pb-safe text-center text-xs text-muted">
        <p>このブラウザに保存されます。Google カレンダーとは同期しません。</p>
        <p className="mt-2">
          <a className="underline" href={import.meta.env.BASE_URL}>
            注文メモへ
          </a>
        </p>
      </footer>

      {dialog ? (
        <EventDialog
          key={dialog.mode === 'edit' ? dialog.event.id : 'create'}
          title={dialog.mode === 'edit' ? '予定を編集' : '予定を追加'}
          description={
            dialog.mode === 'edit' && dialog.event.sample ? 'これは見本の予定です。' : undefined
          }
          initial={dialog.mode === 'edit' ? eventToForm(dialog.event) : dialog.form}
          onClose={() => setDialog(null)}
          onSubmit={submitForm}
          onDelete={
            dialog.mode === 'edit'
              ? () => {
                  remove(dialog.event.id)
                  setDialog(null)
                }
              : undefined
          }
        />
      ) : null}
    </div>
  )
}
