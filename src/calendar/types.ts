export const COLOR_ORDER = ['sage', 'sky', 'sand', 'rose', 'lilac', 'slate'] as const

export type EventColor = (typeof COLOR_ORDER)[number]

export type CalendarView = 'month' | 'week' | 'day'

export type CalendarEvent = {
  id: string
  title: string
  allDay: boolean
  /** 終日は YYYY-MM-DD（両端を含む）。時刻ありは ISO 8601。 */
  start: string
  end: string
  color: EventColor
  location: string
  notes: string
  sample: boolean
}

export type EventForm = {
  title: string
  allDay: boolean
  startDate: string
  startTime: string
  endDate: string
  endTime: string
  color: EventColor
  location: string
  notes: string
}

export const EVENT_COLORS: Record<
  EventColor,
  { label: string; bg: string; fg: string; bar: string }
> = {
  sage: { label: '緑', bg: '#e7f3ec', fg: '#1d4a34', bar: '#2f6a52' },
  sky: { label: '青', bg: '#e6f0f7', fg: '#1d3f5c', bar: '#3d6f92' },
  sand: { label: '砂', bg: '#f8f1e4', fg: '#5c4318', bar: '#b08a45' },
  rose: { label: '紅', bg: '#f8ecec', fg: '#6e2e36', bar: '#b15d68' },
  lilac: { label: '紫', bg: '#f1eef7', fg: '#433a68', bar: '#7a6eaa' },
  slate: { label: '墨', bg: '#eef1f3', fg: '#2c3940', bar: '#5d6d76' },
}

export function isEventColor(value: string): value is EventColor {
  return (COLOR_ORDER as readonly string[]).includes(value)
}
