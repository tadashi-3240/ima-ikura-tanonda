import assert from 'node:assert/strict'
import { describe, it } from 'vitest'
import {
  loadDeviceSchedule,
  readAccess,
  requestAccess,
  type ExpoCalendarModule,
} from './readDeviceSchedule'
import {
  assembleSchedule,
  copy,
  itemsOnDay,
  monthGrid,
  rangeTitle,
  scheduleAccess,
  shiftAnchor,
  visibleRange,
  weekDays,
} from './scheduleModel'
import {
  addDays,
  formatDayHeading,
  startOfWeekMonday,
  todayTokyo,
  tokyoDayKey,
  tokyoParts,
  tokyoStart,
  weekdayJa,
  weekdayMon0,
  ymdKey,
} from './tokyoDate'

describe('Asia/Tokyo dates', () => {
  it('treats 2026-10-01 as Thursday and starts weeks on Monday', () => {
    const day = { year: 2026, month: 10, day: 1 }
    assert.equal(weekdayJa(day), '木')
    assert.equal(weekdayMon0(day), 3)
    assert.deepEqual(startOfWeekMonday(day), { year: 2026, month: 9, day: 28 })
    assert.equal(formatDayHeading(day), '10月1日（木）')
  })

  it('maps Tokyo midnight and the previous UTC evening onto the same calendar day', () => {
    const midnight = tokyoStart({ year: 2026, month: 10, day: 1 })
    assert.equal(midnight.toISOString(), '2026-09-30T15:00:00.000Z')
    assert.equal(tokyoDayKey(midnight), '2026-10-01')
    assert.equal(tokyoDayKey(new Date('2026-09-30T14:59:00.000Z')), '2026-09-30')
    const parts = tokyoParts(new Date('2026-10-01T05:30:00.000Z'))
    assert.equal(parts.hour, 14)
    assert.equal(parts.minute, 30)
  })

  it('builds a Monday-first October 2026 grid and shifts months', () => {
    const grid = monthGrid(2026, 10)
    assert.equal(ymdKey(grid[0]), '2026-09-28')
    assert.equal(ymdKey(grid[grid.length - 1]), '2026-11-01')
    assert.equal(grid.length, 35)
    assert.deepEqual(weekDays({ year: 2026, month: 10, day: 1 }).map(ymdKey), [
      '2026-09-28',
      '2026-09-29',
      '2026-09-30',
      '2026-10-01',
      '2026-10-02',
      '2026-10-03',
      '2026-10-04',
    ])
    assert.deepEqual(shiftAnchor({ year: 2026, month: 1, day: 31 }, 'month', -1), {
      year: 2025,
      month: 12,
      day: 31,
    })
    assert.equal(rangeTitle({ year: 2026, month: 10, day: 1 }, 'month'), '2026年10月')
    assert.equal(rangeTitle({ year: 2026, month: 10, day: 1 }, 'week'), '2026年9月28日〜10月4日')
  })

  it('adds days across a month boundary', () => {
    assert.deepEqual(addDays({ year: 2026, month: 9, day: 30 }, 1), { year: 2026, month: 10, day: 1 })
  })
})

describe('schedule items', () => {
  const october = visibleRange({ year: 2026, month: 10, day: 1 }, 'month')

  it('shows a dated reminder and a calendar event, and drops undated reminders', () => {
    const items = assembleSchedule({
      calendars: [
        { id: 'rem', title: '買い物' },
        { id: 'cal', title: '仕事' },
      ],
      reminders: [
        { id: 'r1', calendarId: 'rem', title: '牛乳', dueDate: '2026-10-01T05:00:00.000Z' },
        { id: 'r-open', calendarId: 'rem', title: 'いつかやる' },
        {
          id: 'r-all-day',
          calendarId: 'rem',
          title: '休み',
          dueDate: '2026-09-30T15:00:00.000Z',
        },
      ],
      events: [
        {
          id: 'e-morning',
          calendarId: 'cal',
          title: '朝礼',
          startDate: '2026-10-01T00:00:00.000Z',
          endDate: '2026-10-01T00:30:00.000Z',
        },
        {
          id: 'e1',
          calendarId: 'cal',
          title: '打ち合わせ',
          startDate: '2026-10-01T05:00:00.000Z',
          endDate: '2026-10-01T06:00:00.000Z',
        },
        {
          id: 'e-cancel',
          calendarId: 'cal',
          title: '中止',
          status: 'canceled',
          startDate: '2026-10-01T05:00:00.000Z',
          endDate: '2026-10-01T06:00:00.000Z',
        },
        {
          id: 'e-all',
          calendarId: 'cal',
          title: '出張',
          allDay: true,
          startDate: '2026-10-03T00:00:00.000Z',
          endDate: '2026-10-05T00:00:00.000Z',
        },
      ],
      dayKeys: october.dayKeys,
    })

    const first = itemsOnDay(items, '2026-10-01')
    assert.deepEqual(
      first.map((item) => item.title),
      ['休み', '朝礼', '牛乳', '打ち合わせ'],
    )
    assert.equal(first[0].kind, 'reminder')
    assert.equal(first[0].allDay, true)
    assert.equal(first[0].timeLabel, '終日')
    assert.equal(first[0].calendarName, '買い物')
    assert.equal(first[1].kind, 'event')
    assert.equal(first[1].timeLabel, '09:00–09:30')
    assert.equal(first[2].timeLabel, '14:00')
    assert.equal(first[2].kind, 'reminder')
    assert.equal(first[3].kind, 'event')
    assert.equal(first[3].timeLabel, '14:00–15:00')
    assert.equal(first[3].calendarName, '仕事')
    assert.equal(items.some((item) => item.title === 'いつかやる'), false)
    assert.equal(items.some((item) => item.title === '中止'), false)
    assert.deepEqual(itemsOnDay(items, '2026-10-03').map((item) => item.title), ['出張'])
    assert.deepEqual(itemsOnDay(items, '2026-10-04').map((item) => item.title), ['出張'])
    assert.deepEqual(itemsOnDay(items, '2026-10-05').map((item) => item.title), [])
  })

  it('repeats a weekly reminder on later days in the visible month', () => {
    const items = assembleSchedule({
      calendars: [{ id: 'rem', title: '個人' }],
      reminders: [
        {
          id: 'weekly',
          calendarId: 'rem',
          title: 'ごみ',
          dueDate: '2026-10-01T00:30:00.000Z',
          recurrenceRule: { frequency: 'weekly', interval: 1 },
        },
      ],
      events: [],
      dayKeys: october.dayKeys,
    })
    const days = ['2026-10-01', '2026-10-08', '2026-10-15', '2026-10-22', '2026-10-29']
    for (const day of days) {
      assert.equal(itemsOnDay(items, day).length, 1, day)
    }
    assert.equal(itemsOnDay(items, '2026-09-24').length, 0)
    assert.equal(itemsOnDay(items, '2026-10-02').length, 0)
  })

  it('does not invent items when the device returns nothing', () => {
    const items = assembleSchedule({
      calendars: [],
      reminders: [],
      events: [],
      dayKeys: october.dayKeys,
    })
    assert.deepEqual(items, [])
    assert.deepEqual(itemsOnDay(items, '2026-10-01'), [])
  })
})

describe('permission copy', () => {
  it('asks in Japanese until access is granted, then shows a partial-permission banner', () => {
    const need = scheduleAccess({
      calendar: 'undetermined',
      reminders: 'undetermined',
      canAskCalendarAgain: true,
      canAskRemindersAgain: true,
      remindersSupported: true,
    })
    assert.equal(need.blocker, 'need')
    assert.equal(need.showCalendar, false)
    assert.equal(copy.allow, '許可する')
    assert.match(copy.needBody, /Apple ID/)

    const denied = scheduleAccess({
      calendar: 'denied',
      reminders: 'denied',
      canAskCalendarAgain: false,
      canAskRemindersAgain: false,
      remindersSupported: true,
    })
    assert.equal(denied.blocker, 'denied')
    assert.equal(copy.allowAgain, 'もう一度許可する')
    assert.equal(copy.openSettings, '設定を開く')

    const partial = scheduleAccess({
      calendar: 'denied',
      reminders: 'granted',
      canAskCalendarAgain: false,
      canAskRemindersAgain: true,
      remindersSupported: true,
    })
    assert.equal(partial.showCalendar, true)
    assert.equal(partial.blocker, null)
    assert.equal(partial.banner?.action, 'settings')
    assert.match(partial.banner?.text ?? '', /カレンダー/)
  })
})

describe('device schedule loading', () => {
  const range = visibleRange({ year: 2026, month: 10, day: 1 }, 'day')

  it('requests calendar and reminder permissions, then reads both with expo-calendar', async () => {
    const calls: string[] = []
    const calendar = fakeCalendar(calls)
    const access = await requestAccess(calendar, 'ios')
    assert.deepEqual(calls, ['requestReminders', 'requestCalendar'])
    assert.equal(access.calendar.status, 'granted')
    assert.equal(access.reminders.status, 'granted')

    calls.length = 0
    const loaded = await loadDeviceSchedule(calendar, access, range)
    assert.deepEqual(calls, ['calendars:event', 'events', 'calendars:reminder', 'reminders'])
    assert.equal(calendar.eventArgs?.[0]?.join(','), 'cal-1')
    assert.equal(calendar.eventArgs?.[1], range.start)
    assert.equal(calendar.eventArgs?.[2], range.end)
    assert.deepEqual(calendar.reminderArgs, [['rem-1'], null, null, null])
    assert.deepEqual(
      loaded.items.map((item) => `${item.kind}:${item.title}`),
      ['reminder:牛乳を買う', 'event:会議'],
    )
    assert.equal(loaded.warning, null)
  })

  it('does not read device data when permission is denied', async () => {
    const calls: string[] = []
    const calendar = fakeCalendar(calls, { calendar: 'denied', reminders: 'denied' })
    const access = await readAccess(calendar, 'ios')
    const loaded = await loadDeviceSchedule(calendar, access, range)
    assert.deepEqual(calls, ['getCalendar', 'getReminders'])
    assert.deepEqual(loaded.items, [])
    assert.equal(access.calendar.canAskAgain, false)
  })

  it('reads events on Android and does not ask for reminders', async () => {
    const calls: string[] = []
    const calendar = fakeCalendar(calls)
    const access = await requestAccess(calendar, 'android')
    assert.deepEqual(calls, ['requestCalendar'])
    assert.equal(access.remindersSupported, false)
    calls.length = 0
    const loaded = await loadDeviceSchedule(calendar, access, range)
    assert.deepEqual(calls, ['calendars:event', 'events'])
    assert.equal(loaded.items[0]?.kind, 'event')
  })

  it('keeps granted reminders when the calendar read fails', async () => {
    const calls: string[] = []
    const calendar = fakeCalendar(calls)
    calendar.getEventsAsync = async () => {
      calls.push('events')
      throw new Error('calendar down')
    }
    const access = await readAccess(calendar, 'ios')
    const loaded = await loadDeviceSchedule(calendar, access, range)
    assert.equal(loaded.items[0]?.kind, 'reminder')
    assert.match(loaded.warning ?? '', /カレンダー/)
  })
})

describe('today', () => {
  it('uses the Tokyo calendar day for the current instant', () => {
    assert.deepEqual(todayTokyo(new Date('2026-09-30T15:00:00.000Z')), {
      year: 2026,
      month: 10,
      day: 1,
    })
  })
})

function fakeCalendar(
  calls: string[],
  initial: { calendar: 'granted' | 'denied' | 'undetermined'; reminders: 'granted' | 'denied' | 'undetermined' } = {
    calendar: 'granted',
    reminders: 'granted',
  },
): ExpoCalendarModule & {
  eventArgs?: [string[], Date, Date]
  reminderArgs?: [(string | null)[], string | null, Date | null, Date | null]
} {
  const permission = (status: 'granted' | 'denied' | 'undetermined') => ({
    status,
    granted: status === 'granted',
    canAskAgain: status !== 'denied',
  })
  const api = {
    eventArgs: undefined as [string[], Date, Date] | undefined,
    reminderArgs: undefined as [(string | null)[], string | null, Date | null, Date | null] | undefined,
    EntityTypes: { EVENT: 'event', REMINDER: 'reminder' },
    async isAvailableAsync() {
      return true
    },
    async getCalendarPermissionsAsync() {
      calls.push('getCalendar')
      return permission(initial.calendar)
    },
    async requestCalendarPermissionsAsync() {
      calls.push('requestCalendar')
      return permission('granted')
    },
    async getRemindersPermissionsAsync() {
      calls.push('getReminders')
      return permission(initial.reminders)
    },
    async requestRemindersPermissionsAsync() {
      calls.push('requestReminders')
      return permission('granted')
    },
    async getCalendarsAsync(entityType?: string) {
      calls.push(`calendars:${entityType}`)
      if (entityType === 'reminder') return [{ id: 'rem-1', title: '買い物' }]
      return [{ id: 'cal-1', title: '個人' }]
    },
    async getEventsAsync(calendarIds: string[], startDate: Date, endDate: Date) {
      calls.push('events')
      api.eventArgs = [calendarIds, startDate, endDate]
      return [
        {
          id: 'event-1',
          calendarId: 'cal-1',
          title: '会議',
          startDate: '2026-10-01T01:00:00.000Z',
          endDate: '2026-10-01T02:00:00.000Z',
        },
      ]
    },
    async getRemindersAsync(
      calendarIds: (string | null)[],
      status: string | null,
      startDate: Date | null,
      endDate: Date | null,
    ) {
      calls.push('reminders')
      api.reminderArgs = [calendarIds, status, startDate, endDate]
      return [
        { id: 'later', calendarId: 'rem-1', title: '来年', dueDate: '2027-01-01T00:00:00.000Z' },
        { id: 'none', calendarId: 'rem-1', title: '日付なし' },
        { id: 'milk', calendarId: 'rem-1', title: '牛乳を買う', dueDate: '2026-10-01T00:30:00.000Z' },
      ]
    },
  }
  return api
}
