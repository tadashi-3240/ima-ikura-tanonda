import * as Calendar from 'expo-calendar'
import { useCallback, useEffect, useState } from 'react'
import {
  loadDeviceSchedule,
  readAccess,
  requestAccess,
  type AccessSnapshot,
} from '../lib/readDeviceSchedule'
import type { ScheduleItem, ViewMode } from '../lib/scheduleModel'
import { visibleRange } from '../lib/scheduleModel'
import type { Ymd } from '../lib/tokyoDate'
import { Platform } from 'react-native'

const emptyAccess: AccessSnapshot = {
  calendar: { status: 'undetermined', canAskAgain: true },
  reminders: { status: 'undetermined', canAskAgain: true },
  remindersSupported: Platform.OS === 'ios',
  available: true,
}

export function useDeviceSchedule(anchor: Ymd, mode: ViewMode) {
  const range = visibleRange(anchor, mode)
  const [access, setAccess] = useState<AccessSnapshot>(emptyAccess)
  const [checked, setChecked] = useState(false)
  const [items, setItems] = useState<ScheduleItem[]>([])
  const [loading, setLoading] = useState(false)
  const [warning, setWarning] = useState<string | null>(null)
  const [reloadToken, setReloadToken] = useState(0)

  useEffect(() => {
    let cancelled = false
    readAccess(Calendar, Platform.OS)
      .then((next) => {
        if (!cancelled) setAccess(next)
      })
      .catch(() => {
        if (!cancelled) {
          setAccess({
            ...emptyAccess,
            calendar: { status: 'unavailable', canAskAgain: false },
            reminders: { status: 'unavailable', canAskAgain: false },
            available: false,
          })
        }
      })
      .finally(() => {
        if (!cancelled) setChecked(true)
      })
    return () => {
      cancelled = true
    }
  }, [])

  const granted = access.calendar.status === 'granted' || access.reminders.status === 'granted'
  const rangeKey = `${range.start.toISOString()}|${range.end.toISOString()}|${range.dayKeys.join(',')}`

  useEffect(() => {
    if (!checked || !granted) return
    let cancelled = false
    setLoading(true)
    loadDeviceSchedule(Calendar, access, range)
      .then((loaded) => {
        if (cancelled) return
        setItems(loaded.items)
        setWarning(loaded.warning)
      })
      .catch(() => {
        if (cancelled) return
        setItems([])
        setWarning('予定を読み込めませんでした')
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
    // range is derived from anchor and mode; rangeKey captures the window.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [checked, granted, access.calendar.status, access.reminders.status, rangeKey, reloadToken])

  const request = useCallback(async () => {
    setLoading(true)
    try {
      const next = await requestAccess(Calendar, Platform.OS)
      setAccess(next)
      setChecked(true)
    } catch {
      setWarning('予定を読み込めませんでした')
    } finally {
      setLoading(false)
    }
  }, [])

  const reload = useCallback(() => {
    setReloadToken((value) => value + 1)
    readAccess(Calendar, Platform.OS)
      .then(setAccess)
      .catch(() => undefined)
  }, [])

  return { access, checked, items, loading, warning, request, reload, range }
}
