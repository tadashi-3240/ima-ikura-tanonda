/** Calendar dates in Asia/Tokyo. Japan has no daylight saving time (UTC+9). */

export const TOKYO = 'Asia/Tokyo'

export type Ymd = {
  year: number
  month: number
  day: number
}

const WEEKDAY_JA = ['日', '月', '火', '水', '木', '金', '土'] as const

export function ymdKey(ymd: Ymd): string {
  const month = String(ymd.month).padStart(2, '0')
  const day = String(ymd.day).padStart(2, '0')
  return `${ymd.year}-${month}-${day}`
}

export function parseKey(key: string): Ymd {
  const [year, month, day] = key.split('-').map(Number)
  return { year, month, day }
}

export function sameYmd(a: Ymd, b: Ymd): boolean {
  return a.year === b.year && a.month === b.month && a.day === b.day
}

export function compareYmd(a: Ymd, b: Ymd): number {
  return ymdKey(a).localeCompare(ymdKey(b))
}

/** 00:00 in Asia/Tokyo as an absolute instant. */
export function tokyoStart(ymd: Ymd): Date {
  return new Date(Date.UTC(ymd.year, ymd.month - 1, ymd.day, -9, 0, 0, 0))
}

export function tokyoParts(date: Date): Ymd & { hour: number; minute: number } {
  const fmt = new Intl.DateTimeFormat('en-US', {
    timeZone: TOKYO,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  })
  const map: Record<string, string> = {}
  for (const part of fmt.formatToParts(date)) {
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

export function tokyoDayKey(date: Date): string {
  return ymdKey(tokyoParts(date))
}

export function todayTokyo(now = new Date()): Ymd {
  const parts = tokyoParts(now)
  return { year: parts.year, month: parts.month, day: parts.day }
}

export function diffDays(from: Ymd, to: Ymd): number {
  const ms = tokyoStart(to).getTime() - tokyoStart(from).getTime()
  return Math.round(ms / 86_400_000)
}

export function addDays(ymd: Ymd, days: number): Ymd {
  const next = new Date(tokyoStart(ymd).getTime() + days * 86_400_000)
  const parts = tokyoParts(next)
  return { year: parts.year, month: parts.month, day: parts.day }
}

export function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate()
}

export function shiftMonth(year: number, month: number, delta: number): { year: number; month: number } {
  const index = year * 12 + (month - 1) + delta
  const shiftedYear = Math.floor(index / 12)
  const shiftedMonth = index - shiftedYear * 12
  return { year: shiftedYear, month: shiftedMonth + 1 }
}

/** Sunday = 0. 2026-10-01 is Thursday. */
export function weekdaySun0(ymd: Ymd): number {
  const knownThursday: Ymd = { year: 2026, month: 10, day: 1 }
  return mod(4 + diffDays(knownThursday, ymd), 7)
}

/** Monday = 0 … Sunday = 6. */
export function weekdayMon0(ymd: Ymd): number {
  return mod(weekdaySun0(ymd) - 1, 7)
}

export function weekdayJa(ymd: Ymd): string {
  return WEEKDAY_JA[weekdaySun0(ymd)]
}

export function startOfWeekMonday(ymd: Ymd): Ymd {
  return addDays(ymd, -weekdayMon0(ymd))
}

export function isTokyoMidnight(date: Date): boolean {
  const parts = tokyoParts(date)
  return parts.hour === 0 && parts.minute === 0
}

export function formatClock(date: Date): string {
  const parts = tokyoParts(date)
  return `${String(parts.hour).padStart(2, '0')}:${String(parts.minute).padStart(2, '0')}`
}

export function formatMonthDay(ymd: Ymd): string {
  return `${ymd.month}月${ymd.day}日`
}

export function formatDayHeading(ymd: Ymd): string {
  return `${ymd.month}月${ymd.day}日（${weekdayJa(ymd)}）`
}

function mod(value: number, divisor: number): number {
  return ((value % divisor) + divisor) % divisor
}
