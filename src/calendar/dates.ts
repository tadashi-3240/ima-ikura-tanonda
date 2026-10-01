export const TIME_ZONE = 'Asia/Tokyo'

export type Ymd = {
  year: number
  month: number
  day: number
}

export const WEEKDAYS = ['月', '火', '水', '木', '金', '土', '日'] as const

const tokyoFormat = new Intl.DateTimeFormat('en-US', {
  timeZone: TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  hourCycle: 'h23',
})

export function pad2(value: number): string {
  return String(value).padStart(2, '0')
}

export function ymdKey(ymd: Ymd): string {
  return `${ymd.year}-${pad2(ymd.month)}-${pad2(ymd.day)}`
}

export function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate()
}

export function parseYmd(value: string): Ymd | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value)
  if (!match) return null
  const year = Number(match[1])
  const month = Number(match[2])
  const day = Number(match[3])
  if (month < 1 || month > 12) return null
  if (day < 1 || day > daysInMonth(year, month)) return null
  return { year, month, day }
}

export function parseHm(value: string): { hour: number; minute: number } | null {
  const match = /^(\d{2}):(\d{2})$/.exec(value)
  if (!match) return null
  const hour = Number(match[1])
  const minute = Number(match[2])
  if (hour > 23 || minute > 59) return null
  return { hour, minute }
}

export function compareYmd(a: Ymd, b: Ymd): number {
  return ymdKey(a).localeCompare(ymdKey(b))
}

export function sameYmd(a: Ymd, b: Ymd): boolean {
  return a.year === b.year && a.month === b.month && a.day === b.day
}

export function addDays(ymd: Ymd, days: number): Ymd {
  const utc = new Date(Date.UTC(ymd.year, ymd.month - 1, ymd.day + days))
  return {
    year: utc.getUTCFullYear(),
    month: utc.getUTCMonth() + 1,
    day: utc.getUTCDate(),
  }
}

function divMod(value: number, divisor: number): { q: number; r: number } {
  const q = Math.floor(value / divisor)
  return { q, r: value - q * divisor }
}

export function addMonths(ymd: Ymd, delta: number): Ymd {
  const { q: year, r } = divMod(ymd.year * 12 + (ymd.month - 1) + delta, 12)
  const month = r + 1
  const day = Math.min(ymd.day, daysInMonth(year, month))
  return { year, month, day }
}

/** 月曜を 0 とする。暦日の曜日はタイムゾーンに依存しない。 */
export function weekdayMon0(ymd: Ymd): number {
  const js = new Date(Date.UTC(ymd.year, ymd.month - 1, ymd.day)).getUTCDay()
  return (js + 6) % 7
}

export function tokyoParts(date: Date): Ymd & { hour: number; minute: number } {
  const map: Record<string, string> = {}
  for (const part of tokyoFormat.formatToParts(date)) {
    if (part.type !== 'literal') map[part.type] = part.value
  }
  let hour = Number(map.hour)
  if (hour === 24) hour = 0
  return {
    year: Number(map.year),
    month: Number(map.month),
    day: Number(map.day),
    hour,
    minute: Number(map.minute),
  }
}

export function tokyoToday(now = new Date()): Ymd {
  const parts = tokyoParts(now)
  return { year: parts.year, month: parts.month, day: parts.day }
}

export function zonedDateTime(ymd: Ymd, hour: number, minute: number): Date {
  return new Date(
    `${ymd.year}-${pad2(ymd.month)}-${pad2(ymd.day)}T${pad2(hour)}:${pad2(minute)}:00+09:00`,
  )
}

export function monthCells(year: number, month: number): Ymd[] {
  const first = { year, month, day: 1 }
  const start = addDays(first, -weekdayMon0(first))
  const last = { year, month, day: daysInMonth(year, month) }
  const end = addDays(last, 6 - weekdayMon0(last))
  const cells: Ymd[] = []
  for (let cursor = start; compareYmd(cursor, end) <= 0; cursor = addDays(cursor, 1)) {
    cells.push(cursor)
  }
  return cells
}

export function weekDays(anchor: Ymd): Ymd[] {
  const start = addDays(anchor, -weekdayMon0(anchor))
  return Array.from({ length: 7 }, (_, index) => addDays(start, index))
}

export function formatMonthTitle(ymd: Ymd): string {
  return `${ymd.year}年${ymd.month}月`
}

export function formatLongDate(ymd: Ymd): string {
  return `${ymd.year}年${ymd.month}月${ymd.day}日（${WEEKDAYS[weekdayMon0(ymd)]}）`
}

export function formatWeekTitle(start: Ymd, end: Ymd): string {
  if (start.year === end.year && start.month === end.month) {
    return `${start.year}年${start.month}月${start.day}日〜${end.day}日`
  }
  if (start.year === end.year) {
    return `${start.year}年${start.month}月${start.day}日〜${end.month}月${end.day}日`
  }
  return `${start.year}年${start.month}月${start.day}日〜${end.year}年${end.month}月${end.day}日`
}

export function rangeLabel(view: 'month' | 'week' | 'day', cursor: Ymd): string {
  if (view === 'month') return formatMonthTitle(cursor)
  if (view === 'day') return formatLongDate(cursor)
  const days = weekDays(cursor)
  return formatWeekTitle(days[0], days[6])
}

export function formatClock(date: Date): string {
  const parts = tokyoParts(date)
  return `${parts.hour}:${pad2(parts.minute)}`
}
