import { tokyoToday } from './dates'
import { buildSampleEvents } from './model'
import { isEventColor, type CalendarEvent } from './types'

export const STORAGE_KEY = 'personal-calendar:v1'

function isEvent(value: unknown): value is CalendarEvent {
  if (typeof value !== 'object' || value === null) return false
  const item = value as Record<string, unknown>
  if (typeof item.id !== 'string' || item.id.length === 0) return false
  if (typeof item.title !== 'string') return false
  if (typeof item.allDay !== 'boolean') return false
  if (typeof item.start !== 'string' || typeof item.end !== 'string') return false
  if (typeof item.color !== 'string' || !isEventColor(item.color)) return false
  if (typeof item.sample !== 'boolean') return false
  if (item.location !== undefined && typeof item.location !== 'string') return false
  if (item.notes !== undefined && typeof item.notes !== 'string') return false
  if (item.allDay) {
    return /^\d{4}-\d{2}-\d{2}$/.test(item.start) && /^\d{4}-\d{2}-\d{2}$/.test(item.end)
  }
  return !Number.isNaN(Date.parse(item.start)) && !Number.isNaN(Date.parse(item.end))
}

function normalize(event: CalendarEvent): CalendarEvent {
  return {
    ...event,
    location: event.location ?? '',
    notes: event.notes ?? '',
  }
}

export function loadEvents(now = new Date()): CalendarEvent[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw === null) return buildSampleEvents(tokyoToday(now))
    const parsed: unknown = JSON.parse(raw)
    if (!Array.isArray(parsed) || !parsed.every(isEvent)) {
      return buildSampleEvents(tokyoToday(now))
    }
    return parsed.map(normalize)
  } catch {
    return buildSampleEvents(tokyoToday(now))
  }
}

export function saveEvents(events: CalendarEvent[]): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(events))
}
