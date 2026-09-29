import { beforeEach, describe, expect, it } from 'vitest'
import { buildSampleEvents } from './model'
import { loadEvents, saveEvents, STORAGE_KEY } from './storage'
import type { CalendarEvent } from './types'

const fixedNow = new Date('2026-09-29T01:00:00.000Z')

const meeting: CalendarEvent = {
  id: 'meeting',
  title: '会議',
  allDay: false,
  start: '2026-09-29T00:00:00.000Z',
  end: '2026-09-29T01:00:00.000Z',
  color: 'lilac',
  location: 'オンライン',
  notes: 'メモ',
  sample: false,
}

describe('カレンダーの localStorage', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('初回は見本の予定を返す', () => {
    const events = loadEvents(fixedNow)
    expect(events.map((event) => event.title)).toEqual(
      buildSampleEvents({ year: 2026, month: 9, day: 29 }).map((event) => event.title),
    )
    expect(localStorage.getItem(STORAGE_KEY)).toBeNull()
  })

  it('空配列は見本で埋め直さない', () => {
    saveEvents([])
    expect(loadEvents(fixedNow)).toEqual([])
  })

  it('保存した予定を復元する', () => {
    saveEvents([meeting])
    expect(loadEvents(fixedNow)).toEqual([meeting])
  })

  it('壊れたデータは見本に戻す', () => {
    localStorage.setItem(STORAGE_KEY, '{')
    expect(loadEvents(fixedNow).every((event) => event.sample)).toBe(true)
    localStorage.setItem(STORAGE_KEY, JSON.stringify([{ id: 1 }]))
    expect(loadEvents(fixedNow).every((event) => event.sample)).toBe(true)
  })
})
