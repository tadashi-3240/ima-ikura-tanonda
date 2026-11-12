import { sameYmd, WEEKDAYS, weekdayMon0, type Ymd } from './dates'
import { eventStartLabel, eventsOnDay } from './model'
import { EVENT_COLORS, type CalendarEvent } from './types'

type Props = {
  cells: Ymd[]
  month: number
  cursor: Ymd
  today: Ymd
  events: CalendarEvent[]
  onSelectDay: (day: Ymd) => void
  onSelectEvent: (event: CalendarEvent) => void
  onCreate: (day: Ymd) => void
}

function dayLabel(day: Ymd, count: number, isToday: boolean, selected: boolean): string {
  const flags = [isToday ? '今日' : '', selected ? '選択中' : ''].filter(Boolean)
  const suffix = flags.length > 0 ? `、${flags.join('、')}` : ''
  return `${day.month}月${day.day}日${suffix}、予定${count}件`
}

export function MonthView({
  cells,
  month,
  cursor,
  today,
  events,
  onSelectDay,
  onSelectEvent,
  onCreate,
}: Props) {
  const selectedEvents = eventsOnDay(events, cursor)

  return (
    <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_18rem] lg:items-start">
      <div className="overflow-hidden rounded-2xl border border-line bg-surface">
        <div className="grid grid-cols-7 border-b border-line text-center text-xs font-semibold text-muted">
          {WEEKDAYS.map((label, index) => (
            <div
              key={label}
              className={`py-2 ${index === 5 ? 'text-sat' : ''} ${index === 6 ? 'text-sun' : ''}`}
            >
              {label}
            </div>
          ))}
        </div>
        <div className="grid grid-cols-7">
          {cells.map((day) => {
            const inMonth = day.month === month
            const isToday = sameYmd(day, today)
            const selected = sameYmd(day, cursor)
            const dayEvents = eventsOnDay(events, day)
            const visible = dayEvents.slice(0, dayEvents.length > 3 ? 2 : 3)
            const hiddenCount = dayEvents.length - visible.length
            const weekend = weekdayMon0(day)
            return (
              <div
                key={`${day.year}-${day.month}-${day.day}`}
                className={`min-h-16 border-t border-r border-line p-1 sm:min-h-28 ${
                  selected ? 'bg-accent-soft' : inMonth ? 'bg-surface' : 'bg-bg'
                }`}
              >
                <button
                  type="button"
                  aria-pressed={selected}
                  aria-label={dayLabel(day, dayEvents.length, isToday, selected)}
                  onClick={() => onSelectDay(day)}
                  className={`inline-flex size-7 items-center justify-center rounded-full text-sm ${
                    isToday ? 'bg-accent font-bold text-white' : ''
                  } ${!isToday && weekend === 5 ? 'text-sat' : ''} ${
                    !isToday && weekend === 6 ? 'text-sun' : ''
                  } ${inMonth || isToday ? '' : 'opacity-45'}`}
                >
                  {day.day}
                </button>
                <div className="mt-1 hidden sm:block">
                  {visible.map((event) => {
                    const color = EVENT_COLORS[event.color]
                    return (
                      <button
                        key={event.id}
                        type="button"
                        onClick={() => onSelectEvent(event)}
                        className="mt-1 flex w-full items-center gap-1 rounded px-1 py-0.5 text-left text-[11px] leading-4"
                        style={{ background: color.bg, color: color.fg }}
                      >
                        <span
                          className="inline-block h-3 w-1 shrink-0 rounded-sm"
                          style={{ background: color.bar }}
                          aria-hidden="true"
                        />
                        <span className="truncate">
                          {eventStartLabel(event)} {event.title}
                        </span>
                      </button>
                    )
                  })}
                  {hiddenCount > 0 ? (
                    <button
                      type="button"
                      className="mt-1 w-full px-1 text-left text-[11px] text-muted"
                      onClick={() => onSelectDay(day)}
                    >
                      他{hiddenCount}件
                    </button>
                  ) : null}
                </div>
                {dayEvents.length > 0 ? (
                  <div className="mt-1 flex gap-0.5 sm:hidden" aria-hidden="true">
                    {dayEvents.slice(0, 3).map((event) => (
                      <span
                        key={event.id}
                        className="size-1.5 rounded-full"
                        style={{ background: EVENT_COLORS[event.color].bar }}
                      />
                    ))}
                  </div>
                ) : null}
              </div>
            )
          })}
        </div>
      </div>

      <aside className="rounded-2xl border border-line bg-surface p-4">
        <h3 className="text-base font-bold">
          {cursor.month}月{cursor.day}日
          {sameYmd(cursor, today) ? '（今日）' : ''}
        </h3>
        <button
          type="button"
          className="mt-3 h-11 w-full rounded-xl border border-line text-sm font-semibold"
          onClick={() => onCreate(cursor)}
        >
          この日に追加
        </button>
        {selectedEvents.length === 0 ? (
          <p className="mt-4 text-sm text-muted">この日の予定はありません</p>
        ) : (
          <ul className="mt-4 space-y-2">
            {selectedEvents.map((event) => {
              const color = EVENT_COLORS[event.color]
              return (
                <li key={event.id}>
                  <button
                    type="button"
                    onClick={() => onSelectEvent(event)}
                    className="w-full rounded-xl px-3 py-2 text-left"
                    style={{ background: color.bg, color: color.fg }}
                  >
                    <span className="block text-xs font-semibold">
                      {eventStartLabel(event)}
                      {event.sample ? ' · 見本' : ''}
                    </span>
                    <span className="mt-0.5 block font-semibold">{event.title}</span>
                    {event.location ? (
                      <span className="mt-0.5 block text-xs">{event.location}</span>
                    ) : null}
                  </button>
                </li>
              )
            })}
          </ul>
        )}
      </aside>
    </div>
  )
}
