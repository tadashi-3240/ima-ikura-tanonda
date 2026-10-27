import {
  addDays,
  compareYmd,
  daysInMonth,
  diffDays,
  formatClock,
  formatDayHeading,
  formatMonthDay,
  isTokyoMidnight,
  parseKey,
  sameYmd,
  shiftMonth,
  startOfWeekMonday,
  tokyoDayKey,
  tokyoParts,
  weekdaySun0,
  ymdKey,
  type Ymd,
} from './tokyoDate'

export type ViewMode = 'month' | 'week' | 'day'

export type Access = 'undetermined' | 'granted' | 'denied' | 'unavailable'

export type RecurrenceRule = {
  frequency: 'daily' | 'weekly' | 'monthly' | 'yearly'
  interval?: number
  endDate?: string | Date
  occurrence?: number
  daysOfTheWeek?: { dayOfTheWeek: number; weekNumber?: number }[]
  daysOfTheMonth?: number[]
  daysOfTheYear?: number[]
  monthsOfTheYear?: number[]
  setPositions?: number[]
  weeksOfTheYear?: number[]
}

export type RawEvent = {
  id: string
  calendarId: string
  title?: string
  allDay?: boolean
  startDate?: string | Date
  endDate?: string | Date
  status?: string
}

export type RawReminder = {
  id?: string
  calendarId?: string
  title?: string
  allDay?: boolean
  startDate?: string | Date
  dueDate?: string | Date
  completed?: boolean
  recurrenceRule?: RecurrenceRule | null
}

export type NamedCalendar = {
  id: string
  title: string
}

export type ScheduleItem = {
  id: string
  kind: 'reminder' | 'event'
  title: string
  calendarName: string
  allDay: boolean
  completed: boolean
  dayKeys: string[]
  sortMinutes: number
  timeLabel: string
}

export type VisibleRange = {
  start: Date
  end: Date
  days: Ymd[]
  dayKeys: string[]
}

export const copy = {
  tabOrders: '注文',
  tabSchedule: '予定',
  title: '予定',
  zone: '日本時間',
  month: '月',
  week: '週',
  day: '日',
  today: '今日',
  previous: '前へ',
  next: '次へ',
  refresh: '更新',
  loading: '読み込み中…',
  emptyDay: 'この日の予定はありません',
  loadError: '予定を読み込めませんでした',
  retry: '再読み込み',
  reminder: 'リマインダー',
  event: 'カレンダー',
  allDay: '終日',
  done: '済',
  untitled: '（無題）',
  needTitle: 'リマインダーとカレンダーを表示します',
  needBody:
    'iPhoneのリマインダーと、カレンダーに入っている予定を読み取ります。Apple IDの入力は不要です。予定の追加や変更はしません。',
  allow: '許可する',
  deniedTitle: 'アクセスがオフです',
  deniedBody:
    '設定でリマインダーとカレンダーを許可すると、予定が表示されます。許可した予定だけを表示し、サンプルの予定は出しません。',
  allowAgain: 'もう一度許可する',
  openSettings: '設定を開く',
  unsupportedTitle: 'iPhoneで開いてください',
  unsupportedBody:
    '予定の読み取りは、iPhoneのリマインダーとカレンダーへの許可が必要です。この画面ではサンプルの予定は表示しません。',
  androidNeedTitle: 'カレンダーを表示します',
  androidNeedBody: 'この端末のカレンダーに入っている予定を読み取ります。予定の追加や変更はしません。',
  androidDeniedBody: '設定でカレンダーを許可すると、予定が表示されます。',
  reminderOff: 'リマインダーへのアクセスがオフです。許可すると、リマインダーの予定も表示されます。',
  reminderAsk: 'リマインダーの許可がまだです。許可すると、リマインダーの予定も表示されます。',
  calendarOff: 'カレンダーへのアクセスがオフです。許可すると、カレンダーの予定も表示されます。',
  calendarAsk: 'カレンダーの許可がまだです。許可すると、カレンダーの予定も表示されます。',
  iphoneReminders: 'リマインダーは iPhone で表示できます。',
}

export function visibleRange(anchor: Ymd, mode: ViewMode): VisibleRange {
  const days =
    mode === 'day' ? [anchor] : mode === 'week' ? weekDays(anchor) : monthGrid(anchor.year, anchor.month)
  const start = days[0]
  const last = days[days.length - 1]
  return {
    start: tokyoStartOf(start),
    end: tokyoStartOf(addDays(last, 1)),
    days,
    dayKeys: days.map(ymdKey),
  }
}

export function monthGrid(year: number, month: number): Ymd[] {
  const first = { year, month, day: 1 }
  const last = { year, month, day: daysInMonth(year, month) }
  const start = startOfWeekMonday(first)
  const end = addDays(startOfWeekMonday(last), 6)
  const days: Ymd[] = []
  let cursor = start
  while (compareYmd(cursor, end) <= 0) {
    days.push(cursor)
    cursor = addDays(cursor, 1)
    if (days.length > 42) break
  }
  return days
}

export function weekDays(anchor: Ymd): Ymd[] {
  const start = startOfWeekMonday(anchor)
  return Array.from({ length: 7 }, (_, index) => addDays(start, index))
}

export function shiftAnchor(anchor: Ymd, mode: ViewMode, delta: number): Ymd {
  if (mode === 'month') {
    const shifted = shiftMonth(anchor.year, anchor.month, delta)
    const day = Math.min(anchor.day, daysInMonth(shifted.year, shifted.month))
    return { year: shifted.year, month: shifted.month, day }
  }
  if (mode === 'week') return addDays(anchor, delta * 7)
  return addDays(anchor, delta)
}

export function rangeTitle(anchor: Ymd, mode: ViewMode): string {
  if (mode === 'month') return `${anchor.year}年${anchor.month}月`
  if (mode === 'day') return formatDayHeading(anchor)
  const start = startOfWeekMonday(anchor)
  const end = addDays(start, 6)
  if (start.year === end.year && start.month === end.month) {
    return `${start.year}年${start.month}月${start.day}日〜${end.day}日`
  }
  if (start.year === end.year) {
    return `${start.year}年${start.month}月${start.day}日〜${end.month}月${end.day}日`
  }
  return `${start.year}年${start.month}月${start.day}日〜${end.year}年${end.month}月${end.day}日`
}

export function previousLabel(mode: ViewMode): string {
  if (mode === 'month') return '前の月'
  if (mode === 'week') return '前の週'
  return '前の日'
}

export function nextLabel(mode: ViewMode): string {
  if (mode === 'month') return '次の月'
  if (mode === 'week') return '次の週'
  return '次の日'
}

export type ScheduleAccess = {
  showCalendar: boolean
  blocker: null | 'need' | 'denied' | 'unsupported'
  banner: null | { text: string; action: 'request' | 'settings' }
}

export function scheduleAccess(input: {
  calendar: Access
  reminders: Access
  canAskCalendarAgain: boolean
  canAskRemindersAgain: boolean
  remindersSupported: boolean
}): ScheduleAccess {
  if (!input.remindersSupported && input.calendar === 'unavailable') {
    return { showCalendar: false, blocker: 'unsupported', banner: null }
  }

  const reminderAccess: Access = input.remindersSupported ? input.reminders : 'unavailable'
  const anyGranted = input.calendar === 'granted' || reminderAccess === 'granted'
  if (!anyGranted) {
    const relevant = input.remindersSupported ? [input.calendar, input.reminders] : [input.calendar]
    const denied = relevant.some((status) => status === 'denied')
    return { showCalendar: false, blocker: denied ? 'denied' : 'need', banner: null }
  }

  if (input.remindersSupported && reminderAccess !== 'granted') {
    const denied = reminderAccess === 'denied'
    return {
      showCalendar: true,
      blocker: null,
      banner: {
        text: denied ? copy.reminderOff : copy.reminderAsk,
        action: denied && !input.canAskRemindersAgain ? 'settings' : 'request',
      },
    }
  }

  if (input.calendar !== 'granted' && input.calendar !== 'unavailable') {
    const denied = input.calendar === 'denied'
    return {
      showCalendar: true,
      blocker: null,
      banner: {
        text: denied ? copy.calendarOff : copy.calendarAsk,
        action: denied && !input.canAskCalendarAgain ? 'settings' : 'request',
      },
    }
  }

  return {
    showCalendar: true,
    blocker: null,
    banner: input.remindersSupported ? null : { text: copy.iphoneReminders, action: 'request' },
  }
}

export function assembleSchedule(input: {
  events: RawEvent[]
  reminders: RawReminder[]
  calendars: NamedCalendar[]
  dayKeys: string[]
}): ScheduleItem[] {
  const names = new Map(input.calendars.map((calendar) => [calendar.id, calendar.title]))
  const visible = new Set(input.dayKeys)
  const items: ScheduleItem[] = []

  input.reminders.forEach((reminder, index) => {
    const item = reminderToItem(reminder, index, names, visible)
    if (item) items.push(item)
  })
  input.events.forEach((event) => {
    const item = eventToItem(event, names, visible)
    if (item) items.push(item)
  })
  return items
}

export function itemsOnDay(items: ScheduleItem[], dayKey: string): ScheduleItem[] {
  return items
    .filter((item) => item.dayKeys.includes(dayKey))
    .sort((a, b) => {
      if (a.allDay !== b.allDay) return a.allDay ? -1 : 1
      if (a.sortMinutes !== b.sortMinutes) return a.sortMinutes - b.sortMinutes
      if (a.kind !== b.kind) return a.kind === 'reminder' ? -1 : 1
      return a.title.localeCompare(b.title, 'ja')
    })
}

export function dayMark(items: ScheduleItem[], dayKey: string): { reminders: number; events: number } | null {
  const onDay = items.filter((item) => item.dayKeys.includes(dayKey))
  if (onDay.length === 0) return null
  return {
    reminders: onDay.filter((item) => item.kind === 'reminder').length,
    events: onDay.filter((item) => item.kind === 'event').length,
  }
}

function reminderToItem(
  reminder: RawReminder,
  index: number,
  names: Map<string, string>,
  visible: Set<string>,
): ScheduleItem | null {
  const due = toDate(reminder.dueDate)
  const start = toDate(reminder.startDate)
  const when = due ?? start
  if (!when) return null

  const allDay = reminder.allDay === true || (reminder.allDay !== false && isTokyoMidnight(when))
  const anchorKey = tokyoDayKey(when)
  const dayKeys = reminder.completed
    ? intersect([anchorKey], visible)
    : recurrenceKeys(anchorKey, reminder.recurrenceRule, visible)
  if (dayKeys.length === 0) return null

  const parts = tokyoParts(when)
  return {
    id: reminder.id || `reminder-${index}-${anchorKey}`,
    kind: 'reminder',
    title: titleOf(reminder.title),
    calendarName: names.get(reminder.calendarId ?? '') || copy.reminder,
    allDay,
    completed: reminder.completed === true,
    dayKeys,
    sortMinutes: allDay ? -1 : parts.hour * 60 + parts.minute,
    timeLabel: allDay ? copy.allDay : formatClock(when),
  }
}

function eventToItem(event: RawEvent, names: Map<string, string>, visible: Set<string>): ScheduleItem | null {
  if (event.status === 'canceled') return null
  const start = toDate(event.startDate)
  if (!start) return null
  const end = toDate(event.endDate)
  const dayKeys = intersect(dayKeysForSpan(start, end, event.allDay === true), visible)
  if (dayKeys.length === 0) return null
  const parts = tokyoParts(start)
  return {
    id: `${event.id}-${tokyoDayKey(start)}`,
    kind: 'event',
    title: titleOf(event.title),
    calendarName: names.get(event.calendarId) || copy.event,
    allDay: event.allDay === true,
    completed: false,
    dayKeys,
    sortMinutes: event.allDay ? -1 : parts.hour * 60 + parts.minute,
    timeLabel: formatSpanLabel(start, end, event.allDay === true),
  }
}

function recurrenceKeys(anchorKey: string, rule: RecurrenceRule | null | undefined, visible: Set<string>): string[] {
  if (!rule || !simpleRule(rule)) return intersect([anchorKey], visible)
  const anchor = parseKey(anchorKey)
  const end = rule.endDate ? parseKey(tokyoDayKey(toDate(rule.endDate) ?? tokyoStartOf(anchor))) : null
  const interval = Math.max(1, rule.interval ?? 1)
  const matched: string[] = []
  for (const key of visible) {
    const day = parseKey(key)
    if (compareYmd(day, anchor) < 0) continue
    if (end && compareYmd(day, end) > 0) continue
    if (!matchesRule(day, anchor, rule, interval)) continue
    matched.push(key)
  }
  matched.sort()
  if (rule.occurrence && rule.occurrence > 0) return matched.slice(0, rule.occurrence)
  return matched
}

function simpleRule(rule: RecurrenceRule): boolean {
  if (rule.daysOfTheYear?.length) return false
  if (rule.monthsOfTheYear?.length) return false
  if (rule.setPositions?.length) return false
  if (rule.weeksOfTheYear?.length) return false
  if (rule.daysOfTheWeek?.some((day) => day.weekNumber)) return false
  return rule.frequency === 'daily' || rule.frequency === 'weekly' || rule.frequency === 'monthly' || rule.frequency === 'yearly'
}

function matchesRule(day: Ymd, anchor: Ymd, rule: RecurrenceRule, interval: number): boolean {
  if (rule.frequency === 'daily') return mod(diffDays(anchor, day), interval) === 0
  if (rule.frequency === 'weekly') {
    const weekdays = rule.daysOfTheWeek?.map((entry) => entry.dayOfTheWeek)
    const iosWeekday = weekdaySun0(day) + 1
    if (weekdays?.length && !weekdays.includes(iosWeekday)) return false
    if (!weekdays?.length && weekdaySun0(day) !== weekdaySun0(anchor)) return false
    const weeks = diffDays(startOfWeekMonday(anchor), startOfWeekMonday(day)) / 7
    return mod(weeks, interval) === 0
  }
  if (rule.frequency === 'monthly') {
    if (rule.daysOfTheMonth?.length) {
      if (!monthDayMatches(day, rule.daysOfTheMonth)) return false
    } else if (day.day !== anchor.day) {
      return false
    }
    const months = (day.year - anchor.year) * 12 + (day.month - anchor.month)
    return mod(months, interval) === 0
  }
  if (day.month !== anchor.month || day.day !== anchor.day) return false
  return mod(day.year - anchor.year, interval) === 0
}

function monthDayMatches(day: Ymd, daysOfTheMonth: number[]): boolean {
  const length = daysInMonth(day.year, day.month)
  return daysOfTheMonth.some((value) => {
    if (value > 0) return day.day === value
    if (value < 0) return day.day === length + value + 1
    return false
  })
}

function dayKeysForSpan(start: Date, end: Date | null, allDay: boolean): string[] {
  const startKey = tokyoDayKey(start)
  if (!end || end.getTime() <= start.getTime()) return [startKey]
  const endKey = tokyoDayKey(end)
  const exclusive = allDay || isTokyoMidnight(end)
  if (!exclusive) {
    const keys: string[] = []
    let cursor = parseKey(startKey)
    while (true) {
      const key = ymdKey(cursor)
      keys.push(key)
      if (key === endKey) break
      cursor = addDays(cursor, 1)
      if (keys.length > 370) break
    }
    return keys
  }
  if (startKey === endKey) return [startKey]
  const keys: string[] = []
  let cursor = parseKey(startKey)
  while (ymdKey(cursor) !== endKey) {
    keys.push(ymdKey(cursor))
    cursor = addDays(cursor, 1)
    if (keys.length > 370) break
  }
  return keys.length > 0 ? keys : [startKey]
}

function formatSpanLabel(start: Date, end: Date | null, allDay: boolean): string {
  if (allDay) return copy.allDay
  const startLabel = formatClock(start)
  if (!end) return startLabel
  const sameDay = tokyoDayKey(start) === tokyoDayKey(end) || (isTokyoMidnight(end) && end.getTime() > start.getTime())
  if (sameDay) {
    const endLabel = isTokyoMidnight(end) ? '' : formatClock(end)
    if (!endLabel || endLabel === startLabel) return startLabel
    return `${startLabel}–${endLabel}`
  }
  const startDay = tokyoParts(start)
  const endDay = tokyoParts(end)
  return `${formatMonthDay(startDay)} ${startLabel}–${formatMonthDay(endDay)} ${formatClock(end)}`
}

function intersect(keys: string[], visible: Set<string>): string[] {
  return keys.filter((key) => visible.has(key))
}

function titleOf(title: string | undefined): string {
  const trimmed = title?.trim()
  return trimmed ? trimmed : copy.untitled
}

function toDate(value: string | Date | undefined | null): Date | null {
  if (!value) return null
  const date = value instanceof Date ? value : new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

function tokyoStartOf(ymd: Ymd): Date {
  return new Date(Date.UTC(ymd.year, ymd.month - 1, ymd.day, -9, 0, 0, 0))
}

function mod(value: number, divisor: number): number {
  return ((value % divisor) + divisor) % divisor
}

export function inMonth(day: Ymd, year: number, month: number): boolean {
  return day.year === year && day.month === month
}

export function isSameDay(a: Ymd, b: Ymd): boolean {
  return sameYmd(a, b)
}
