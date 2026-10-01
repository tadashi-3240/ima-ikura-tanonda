import { describe, expect, it } from 'vitest'
import {
  addDays,
  addMonths,
  monthCells,
  rangeLabel,
  tokyoParts,
  weekDays,
  weekdayMon0,
  zonedDateTime,
} from './dates'

describe('日本時間の暦', () => {
  it('2026-09-29 は火曜で、月のマスは月曜から始まる', () => {
    const today = { year: 2026, month: 9, day: 29 }
    expect(weekdayMon0(today)).toBe(1)

    const cells = monthCells(2026, 9)
    expect(cells.length % 7).toBe(0)
    expect(weekdayMon0(cells[0])).toBe(0)
    expect(cells[0]).toEqual({ year: 2026, month: 8, day: 31 })
    expect(cells.at(-1)).toEqual({ year: 2026, month: 10, day: 4 })
    expect(cells.some((day) => day.day === 1 && day.month === 9)).toBe(true)
  })

  it('週は月曜から日曜', () => {
    const days = weekDays({ year: 2026, month: 9, day: 29 })
    expect(days[0]).toEqual({ year: 2026, month: 9, day: 28 })
    expect(days[6]).toEqual({ year: 2026, month: 10, day: 4 })
    expect(weekdayMon0(days[0])).toBe(0)
    expect(weekdayMon0(days[6])).toBe(6)
  })

  it('月末をまたぐ月送りは日を切り詰める', () => {
    expect(addMonths({ year: 2026, month: 1, day: 31 }, 1)).toEqual({
      year: 2026,
      month: 2,
      day: 28,
    })
    expect(addMonths({ year: 2026, month: 1, day: 15 }, -1)).toEqual({
      year: 2025,
      month: 12,
      day: 15,
    })
    expect(addDays({ year: 2026, month: 9, day: 30 }, 1)).toEqual({
      year: 2026,
      month: 10,
      day: 1,
    })
  })

  it('UTC 深夜でも日本時間の日付になる', () => {
    const parts = tokyoParts(new Date('2026-09-28T15:30:00.000Z'))
    expect(parts).toMatchObject({ year: 2026, month: 9, day: 29, hour: 0, minute: 30 })
    expect(zonedDateTime({ year: 2026, month: 9, day: 29 }, 0, 30).toISOString()).toBe(
      '2026-09-28T15:30:00.000Z',
    )
  })

  it('表示ラベル', () => {
    const cursor = { year: 2026, month: 9, day: 29 }
    expect(rangeLabel('month', cursor)).toBe('2026年9月')
    expect(rangeLabel('day', cursor)).toBe('2026年9月29日（火）')
    expect(rangeLabel('week', cursor)).toBe('2026年9月28日〜10月4日')
  })
})
