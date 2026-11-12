import {
  addDays,
  compareYmd,
  formatClock,
  pad2,
  parseHm,
  parseYmd,
  tokyoParts,
  weekdayMon0,
  ymdKey,
  zonedDateTime,
  type Ymd,
} from './dates'
import { isEventColor, type CalendarEvent, type EventForm } from './types'

export function occursOn(event: CalendarEvent, day: Ymd): boolean {
  const dayStart = zonedDateTime(day, 0, 0).getTime()
  const dayEnd = zonedDateTime(addDays(day, 1), 0, 0).getTime()
  const range = eventRange(event)
  return range.startMs < dayEnd && range.endMs > dayStart
}

export function eventRange(event: CalendarEvent): { startMs: number; endMs: number } {
  if (event.allDay) {
    const start = parseYmd(event.start)
    const end = parseYmd(event.end)
    if (!start || !end) return { startMs: 0, endMs: 0 }
    return {
      startMs: zonedDateTime(start, 0, 0).getTime(),
      endMs: zonedDateTime(addDays(end, 1), 0, 0).getTime(),
    }
  }
  const startMs = new Date(event.start).getTime()
  const endMs = new Date(event.end).getTime()
  return { startMs, endMs }
}

export function eventStartLabel(event: CalendarEvent): string {
  if (event.allDay) return '終日'
  return formatClock(new Date(event.start))
}

export function eventsOnDay(events: CalendarEvent[], day: Ymd): CalendarEvent[] {
  return events
    .filter((event) => occursOn(event, day))
    .sort((a, b) => {
      if (a.allDay !== b.allDay) return a.allDay ? -1 : 1
      return eventRange(a).startMs - eventRange(b).startMs
    })
}

export function timedSlice(
  event: CalendarEvent,
  day: Ymd,
): { startMin: number; endMin: number } | null {
  if (event.allDay || !occursOn(event, day)) return null
  const dayStart = zonedDateTime(day, 0, 0).getTime()
  const dayEnd = zonedDateTime(addDays(day, 1), 0, 0).getTime()
  const range = eventRange(event)
  const start = Math.max(range.startMs, dayStart)
  const end = Math.min(range.endMs, dayEnd)
  const startMin = Math.floor((start - dayStart) / 60000)
  const endMin = Math.max(Math.ceil((end - dayStart) / 60000), startMin + 15)
  return { startMin, endMin: Math.min(endMin, 24 * 60) }
}

export type LanePlacement = {
  id: string
  lane: number
  laneCount: number
  startMin: number
  endMin: number
}

export function assignLanes(
  items: { id: string; startMin: number; endMin: number }[],
): LanePlacement[] {
  const sorted = [...items].sort(
    (a, b) => a.startMin - b.startMin || a.endMin - b.endMin,
  )
  const laneEnds: number[] = []
  const placed: { id: string; lane: number; startMin: number; endMin: number }[] = []

  for (const item of sorted) {
    let lane = laneEnds.findIndex((end) => end <= item.startMin)
    if (lane === -1) {
      lane = laneEnds.length
      laneEnds.push(item.endMin)
    } else {
      laneEnds[lane] = item.endMin
    }
    placed.push({
      id: item.id,
      lane,
      startMin: item.startMin,
      endMin: item.endMin,
    })
  }

  const parent = placed.map((_, index) => index)
  const find = (index: number): number => {
    if (parent[index] !== index) parent[index] = find(parent[index])
    return parent[index]
  }
  const union = (a: number, b: number) => {
    const pa = find(a)
    const pb = find(b)
    if (pa !== pb) parent[pa] = pb
  }

  for (let i = 0; i < placed.length; i++) {
    for (let j = i + 1; j < placed.length; j++) {
      const left = placed[i]
      const right = placed[j]
      if (left.startMin < right.endMin && right.startMin < left.endMin) union(i, j)
    }
  }

  const countByRoot = new Map<number, number>()
  for (let i = 0; i < placed.length; i++) {
    const root = find(i)
    countByRoot.set(root, Math.max(countByRoot.get(root) ?? 1, placed[i].lane + 1))
  }

  return placed.map((item, index) => ({
    ...item,
    laneCount: countByRoot.get(find(index)) ?? 1,
  }))
}

function ymdFromInstant(date: Date): Ymd {
  const parts = tokyoParts(date)
  return { year: parts.year, month: parts.month, day: parts.day }
}

function clockFromInstant(date: Date): string {
  const parts = tokyoParts(date)
  return `${pad2(parts.hour)}:${pad2(parts.minute)}`
}

export function draftForSlot(day: Ymd, hour = 9): EventForm {
  const safeHour = Math.min(Math.max(hour, 0), 23)
  const start = zonedDateTime(day, safeHour, 0)
  const end = new Date(start.getTime() + 60 * 60 * 1000)
  return {
    title: '',
    allDay: false,
    startDate: ymdKey(day),
    startTime: `${pad2(safeHour)}:00`,
    endDate: ymdKey(ymdFromInstant(end)),
    endTime: clockFromInstant(end),
    color: 'sage',
    location: '',
    notes: '',
  }
}

export function eventToForm(event: CalendarEvent): EventForm {
  if (event.allDay) {
    return {
      title: event.title,
      allDay: true,
      startDate: event.start,
      startTime: '09:00',
      endDate: event.end,
      endTime: '10:00',
      color: event.color,
      location: event.location,
      notes: event.notes,
    }
  }
  return {
    title: event.title,
    allDay: false,
    startDate: ymdKey(ymdFromInstant(new Date(event.start))),
    startTime: clockFromInstant(new Date(event.start)),
    endDate: ymdKey(ymdFromInstant(new Date(event.end))),
    endTime: clockFromInstant(new Date(event.end)),
    color: event.color,
    location: event.location,
    notes: event.notes,
  }
}

export function formToEvent(
  form: EventForm,
  id: string,
  sample: boolean,
): { ok: true; event: CalendarEvent } | { ok: false; message: string } {
  const title = form.title.trim()
  if (!title) return { ok: false, message: 'タイトルを入力してください' }
  if (!isEventColor(form.color)) return { ok: false, message: '色を選んでください' }

  const startDay = parseYmd(form.startDate)
  const endDay = parseYmd(form.endDate)
  if (!startDay || !endDay) return { ok: false, message: '日付を確認してください' }

  const location = form.location.trim()
  const notes = form.notes.trim()

  if (form.allDay) {
    if (compareYmd(endDay, startDay) < 0) {
      return { ok: false, message: '終了日は開始日以降にしてください' }
    }
    return {
      ok: true,
      event: {
        id,
        title,
        allDay: true,
        start: ymdKey(startDay),
        end: ymdKey(endDay),
        color: form.color,
        location,
        notes,
        sample,
      },
    }
  }

  const startHm = parseHm(form.startTime)
  const endHm = parseHm(form.endTime)
  if (!startHm || !endHm) return { ok: false, message: '時刻を確認してください' }

  const start = zonedDateTime(startDay, startHm.hour, startHm.minute)
  const end = zonedDateTime(endDay, endHm.hour, endHm.minute)
  if (!(end.getTime() > start.getTime())) {
    return { ok: false, message: '終了は開始より後にしてください' }
  }

  return {
    ok: true,
    event: {
      id,
      title,
      allDay: false,
      start: start.toISOString(),
      end: end.toISOString(),
      color: form.color,
      location,
      notes,
      sample,
    },
  }
}

export function buildSampleEvents(today: Ymd): CalendarEvent[] {
  const errandOffset = weekdayMon0(today) === 6 ? -1 : 1
  const errandDay = addDays(today, errandOffset)
  const holiday = addDays(today, 5 - weekdayMon0(today))
  const morningStart = zonedDateTime(today, 9, 0)
  const morningEnd = zonedDateTime(today, 10, 0)
  const errandStart = zonedDateTime(errandDay, 14, 30)
  const errandEnd = zonedDateTime(errandDay, 15, 30)

  return [
    {
      id: 'sample-morning',
      title: 'サンプル：朝の打ち合わせ',
      allDay: false,
      start: morningStart.toISOString(),
      end: morningEnd.toISOString(),
      color: 'sage',
      location: 'オンライン',
      notes: '見本の予定です。編集や削除ができます。',
      sample: true,
    },
    {
      id: 'sample-errand',
      title: 'サンプル：歯医者',
      allDay: false,
      start: errandStart.toISOString(),
      end: errandEnd.toISOString(),
      color: 'sky',
      location: '駅前クリニック',
      notes: '見本の予定です。',
      sample: true,
    },
    {
      id: 'sample-holiday',
      title: 'サンプル：休日',
      allDay: true,
      start: ymdKey(holiday),
      end: ymdKey(holiday),
      color: 'sand',
      location: '',
      notes: '終日の見本です。',
      sample: true,
    },
  ]
}

export function eventFallsInWeek(event: CalendarEvent, today: Ymd): boolean {
  const start = addDays(today, -weekdayMon0(today))
  return Array.from({ length: 7 }, (_, index) => addDays(start, index)).some((day) =>
    occursOn(event, day),
  )
}
