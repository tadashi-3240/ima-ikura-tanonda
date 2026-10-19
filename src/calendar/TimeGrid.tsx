import { useEffect, useRef } from 'react'
import { formatLongDate, sameYmd, tokyoParts, WEEKDAYS, weekdayMon0, type Ymd } from './dates'
import { assignLanes, eventStartLabel, eventsOnDay, timedSlice } from './model'
import { EVENT_COLORS, type CalendarEvent } from './types'

const HOUR_PX = 52

type Props = {
  days: Ymd[]
  today: Ymd
  now: Date
  events: CalendarEvent[]
  onOpenDay: (day: Ymd) => void
  onSelectEvent: (event: CalendarEvent) => void
  onCreateAt: (day: Ymd, hour: number) => void
}

export function TimeGrid({
  days,
  today,
  now,
  events,
  onOpenDay,
  onSelectEvent,
  onCreateAt,
}: Props) {
  const scrollerRef = useRef<HTMLDivElement>(null)
  const dayKey = days.map((day) => `${day.year}-${day.month}-${day.day}`).join('|')
  const wide = days.length > 1
  const columns = `3.25rem repeat(${days.length}, minmax(0, 1fr))`

  useEffect(() => {
    const scroller = scrollerRef.current
    if (!scroller) return
    scroller.scrollTop = 8 * HOUR_PX
  }, [dayKey])

  const nowClock = tokyoParts(now)
  const nowMinutes = nowClock.hour * 60 + nowClock.minute

  return (
    <div className="overflow-hidden rounded-2xl border border-line bg-surface">
      {wide ? (
        <p className="border-b border-line px-3 py-2 text-xs text-muted sm:hidden">
          左右にスクロールすると、週全体を見られます。
        </p>
      ) : null}
      <div className={wide ? 'overflow-x-auto' : ''}>
        <div className={wide ? 'min-w-[44rem]' : ''}>
          <div className="grid border-b border-line" style={{ gridTemplateColumns: columns }}>
            <div />
            {days.map((day) => {
              const isToday = sameYmd(day, today)
              const weekend = weekdayMon0(day)
              return (
                <div key={`${day.year}-${day.month}-${day.day}`} className="px-1 py-2 text-center">
                  <div
                    className={`text-xs ${weekend === 5 ? 'text-sat' : ''} ${
                      weekend === 6 ? 'text-sun' : ''
                    } ${isToday ? 'font-bold text-accent' : 'text-muted'}`}
                  >
                    {WEEKDAYS[weekend]}
                  </div>
                  <button
                    type="button"
                    onClick={() => onOpenDay(day)}
                    aria-label={`${formatLongDate(day)}を日表示で開く`}
                    className={`mx-auto mt-1 inline-flex size-8 items-center justify-center rounded-full text-sm ${
                      isToday ? 'bg-accent font-bold text-white' : ''
                    }`}
                  >
                    {day.day}
                  </button>
                </div>
              )
            })}
            <div className="border-t border-line px-1 py-2 text-right text-[11px] text-muted">
              終日
            </div>
            {days.map((day) => {
              const allDay = eventsOnDay(events, day).filter((event) => event.allDay)
              return (
                <div
                  key={`all-${day.year}-${day.month}-${day.day}`}
                  className="space-y-1 border-t border-l border-line p-1"
                >
                  {allDay.map((event) => {
                    const color = EVENT_COLORS[event.color]
                    return (
                      <button
                        key={event.id}
                        type="button"
                        onClick={() => onSelectEvent(event)}
                        className="block w-full truncate rounded px-1 py-0.5 text-left text-[11px]"
                        style={{ background: color.bg, color: color.fg }}
                      >
                        {event.title}
                      </button>
                    )
                  })}
                </div>
              )
            })}
          </div>

          <div ref={scrollerRef} className="max-h-[min(70dvh,720px)] overflow-y-auto">
            <div className="grid" style={{ gridTemplateColumns: columns }}>
              <div className="relative border-r border-line" style={{ height: 24 * HOUR_PX }}>
                {Array.from({ length: 24 }, (_, hour) => (
                  <div
                    key={hour}
                    className="absolute right-1 text-[11px] text-muted"
                    style={{ top: hour * HOUR_PX + 2 }}
                  >
                    {hour}:00
                  </div>
                ))}
              </div>
              {days.map((day) => {
                const isToday = sameYmd(day, today)
                const timed = eventsOnDay(events, day).flatMap((event) => {
                  const slice = timedSlice(event, day)
                  return slice ? [{ event, ...slice }] : []
                })
                const lanes = assignLanes(
                  timed.map((item) => ({
                    id: item.event.id,
                    startMin: item.startMin,
                    endMin: item.endMin,
                  })),
                )
                const laneById = new Map(lanes.map((lane) => [lane.id, lane]))
                return (
                  <div
                    key={`col-${day.year}-${day.month}-${day.day}`}
                    className="relative border-l border-line"
                    style={{ height: 24 * HOUR_PX }}
                    onClick={(event) => {
                      const target = event.target
                      if (target instanceof Element && target.closest('button')) return
                      const rect = event.currentTarget.getBoundingClientRect()
                      const y = event.clientY - rect.top
                      const hour = Math.max(0, Math.min(23, Math.floor(y / HOUR_PX)))
                      onCreateAt(day, hour)
                    }}
                  >
                    {Array.from({ length: 24 }, (_, hour) => (
                      <div
                        key={hour}
                        className="pointer-events-none absolute right-0 left-0 border-t border-line"
                        style={{ top: hour * HOUR_PX }}
                      />
                    ))}
                    {isToday ? (
                      <div
                        className="pointer-events-none absolute right-1 left-1 z-20 border-t-2 border-now"
                        style={{ top: (nowMinutes / 60) * HOUR_PX }}
                      />
                    ) : null}
                    {timed.map(({ event, startMin, endMin }) => {
                      const lane = laneById.get(event.id)
                      const laneIndex = lane?.lane ?? 0
                      const laneCount = lane?.laneCount ?? 1
                      const color = EVENT_COLORS[event.color]
                      return (
                        <button
                          key={event.id}
                          type="button"
                          onClick={(click) => {
                            click.stopPropagation()
                            onSelectEvent(event)
                          }}
                          className="absolute z-10 overflow-hidden rounded-md px-1 py-0.5 text-left text-[11px] leading-tight"
                          style={{
                            top: (startMin / 60) * HOUR_PX + 1,
                            height: Math.max(((endMin - startMin) / 60) * HOUR_PX - 2, 22),
                            left: `calc(${(laneIndex / laneCount) * 100}% + 2px)`,
                            width: `calc(${100 / laneCount}% - 4px)`,
                            background: color.bg,
                            color: color.fg,
                            borderLeft: `3px solid ${color.bar}`,
                          }}
                        >
                          <span className="block truncate font-semibold">
                            {eventStartLabel(event)} {event.title}
                          </span>
                        </button>
                      )
                    })}
                  </div>
                )
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
