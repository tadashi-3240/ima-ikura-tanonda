import { useCallback, useEffect, useState } from 'react'
import { loadEvents, saveEvents } from './storage'
import type { CalendarEvent } from './types'

export function useEvents() {
  const [events, setEvents] = useState<CalendarEvent[]>(() => loadEvents())

  useEffect(() => {
    saveEvents(events)
  }, [events])

  const upsert = useCallback((event: CalendarEvent) => {
    setEvents((current) => {
      const index = current.findIndex((item) => item.id === event.id)
      if (index === -1) return [...current, event]
      return current.map((item) => (item.id === event.id ? event : item))
    })
  }, [])

  const remove = useCallback((id: string) => {
    setEvents((current) => current.filter((item) => item.id !== id))
  }, [])

  return { events, upsert, remove }
}
