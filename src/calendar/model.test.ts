import { describe, expect, it } from 'vitest'
import { weekDays } from './dates'
import {
  assignLanes,
  buildSampleEvents,
  eventFallsInWeek,
  formToEvent,
  occursOn,
} from './model'
import type { CalendarEvent } from './types'

function timed(
  start: string,
  end: string,
  extra: Partial<CalendarEvent> = {},
): CalendarEvent {
  return {
    id: 'event',
    title: '予定',
    allDay: false,
    start,
    end,
    color: 'sage',
    location: '',
    notes: '',
    sample: false,
    ...extra,
  }
}

describe('予定の日付', () => {
  const today = { year: 2026, month: 9, day: 29 }

  it('見本は今週の中にあり、サンプルと分かる', () => {
    const samples = buildSampleEvents(today)
    expect(samples).toHaveLength(3)
    expect(samples.every((event) => event.sample && event.title.includes('サンプル'))).toBe(true)
    expect(new Set(samples.map((event) => event.id)).size).toBe(3)
    const week = weekDays(today)
    for (const event of samples) {
      expect(eventFallsInWeek(event, today)).toBe(true)
      expect(week.some((day) => occursOn(event, day))).toBe(true)
    }
  })

  it('終日予定は終了日を含み、翌日は含まない', () => {
    const event: CalendarEvent = {
      id: 'off',
      title: '休み',
      allDay: true,
      start: '2026-09-29',
      end: '2026-09-30',
      color: 'sand',
      location: '',
      notes: '',
      sample: false,
    }
    expect(occursOn(event, { year: 2026, month: 9, day: 28 })).toBe(false)
    expect(occursOn(event, { year: 2026, month: 9, day: 29 })).toBe(true)
    expect(occursOn(event, { year: 2026, month: 9, day: 30 })).toBe(true)
    expect(occursOn(event, { year: 2026, month: 10, day: 1 })).toBe(false)
  })

  it('日本時間の深夜の予定は前日に出ない', () => {
    const event = timed('2026-09-28T15:30:00.000Z', '2026-09-28T16:00:00.000Z')
    expect(occursOn(event, { year: 2026, month: 9, day: 29 })).toBe(true)
    expect(occursOn(event, { year: 2026, month: 9, day: 28 })).toBe(false)
  })

  it('重なる予定は別レーンになる', () => {
    const lanes = assignLanes([
      { id: 'a', startMin: 9 * 60, endMin: 11 * 60 },
      { id: 'b', startMin: 10 * 60, endMin: 12 * 60 },
      { id: 'c', startMin: 13 * 60, endMin: 14 * 60 },
    ])
    const byId = Object.fromEntries(lanes.map((lane) => [lane.id, lane]))
    expect(byId.a.lane).not.toBe(byId.b.lane)
    expect(byId.a.laneCount).toBe(2)
    expect(byId.b.laneCount).toBe(2)
    expect(byId.c.laneCount).toBe(1)
  })

  it('入力チェック', () => {
    const base = {
      title: '  会議  ',
      allDay: false,
      startDate: '2026-09-29',
      startTime: '09:00',
      endDate: '2026-09-29',
      endTime: '10:00',
      color: 'sage' as const,
      location: ' 会議室 ',
      notes: '',
    }
    expect(formToEvent({ ...base, title: '   ' }, 'id', false)).toMatchObject({
      ok: false,
      message: 'タイトルを入力してください',
    })
    expect(formToEvent({ ...base, endTime: '08:00' }, 'id', false)).toMatchObject({
      ok: false,
      message: '終了は開始より後にしてください',
    })
    expect(
      formToEvent(
        { ...base, allDay: true, startDate: '2026-09-30', endDate: '2026-09-29' },
        'id',
        false,
      ),
    ).toMatchObject({ ok: false, message: '終了日は開始日以降にしてください' })

    const saved = formToEvent(base, 'id', true)
    expect(saved.ok).toBe(true)
    if (!saved.ok) return
    expect(saved.event.title).toBe('会議')
    expect(saved.event.location).toBe('会議室')
    expect(saved.event.start).toBe('2026-09-29T00:00:00.000Z')
    expect(saved.event.sample).toBe(true)
  })
})
