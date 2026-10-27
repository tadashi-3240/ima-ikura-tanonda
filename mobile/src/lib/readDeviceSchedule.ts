import {
  assembleSchedule,
  type Access,
  type NamedCalendar,
  type RawEvent,
  type RawReminder,
  type ScheduleItem,
} from './scheduleModel'

export type DevicePermission = {
  status: Access
  canAskAgain: boolean
}

export type DeviceCalendarRecord = NamedCalendar

export type ExpoCalendarModule = {
  isAvailableAsync?: () => Promise<boolean>
  getCalendarPermissionsAsync: () => Promise<PermissionLike>
  requestCalendarPermissionsAsync: () => Promise<PermissionLike>
  getRemindersPermissionsAsync: () => Promise<PermissionLike>
  requestRemindersPermissionsAsync: () => Promise<PermissionLike>
  getCalendarsAsync: (entityType?: string) => Promise<DeviceCalendarRecord[]>
  getEventsAsync: (calendarIds: string[], startDate: Date, endDate: Date) => Promise<RawEvent[]>
  getRemindersAsync: (
    calendarIds: (string | null)[],
    status: null,
    startDate: null,
    endDate: null,
  ) => Promise<RawReminder[]>
  EntityTypes: { EVENT: string; REMINDER: string }
}

type PermissionLike = {
  status?: string
  granted?: boolean
  canAskAgain?: boolean
}

export type AccessSnapshot = {
  calendar: DevicePermission
  reminders: DevicePermission
  remindersSupported: boolean
  available: boolean
}

export type LoadedSchedule = {
  items: ScheduleItem[]
  warning: string | null
}

const unavailablePermission: DevicePermission = { status: 'unavailable', canAskAgain: false }

export async function readAccess(calendar: ExpoCalendarModule, platform: string): Promise<AccessSnapshot> {
  const remindersSupported = platform === 'ios'
  const available = calendar.isAvailableAsync ? await calendar.isAvailableAsync() : true
  if (!available) {
    return {
      calendar: unavailablePermission,
      reminders: unavailablePermission,
      remindersSupported,
      available: false,
    }
  }

  const calendarPermission = normalize(await calendar.getCalendarPermissionsAsync())
  const reminders = remindersSupported
    ? normalize(await calendar.getRemindersPermissionsAsync())
    : unavailablePermission
  return { calendar: calendarPermission, reminders, remindersSupported, available: true }
}

export async function requestAccess(calendar: ExpoCalendarModule, platform: string): Promise<AccessSnapshot> {
  const remindersSupported = platform === 'ios'
  const available = calendar.isAvailableAsync ? await calendar.isAvailableAsync() : true
  if (!available) return readAccess(calendar, platform)

  const reminders = remindersSupported
    ? normalize(await calendar.requestRemindersPermissionsAsync())
    : unavailablePermission
  const calendarPermission = normalize(await calendar.requestCalendarPermissionsAsync())
  return { calendar: calendarPermission, reminders, remindersSupported, available: true }
}

/**
 * Reads on-device calendars and, on iOS, reminders.
 * Reminders are fetched with a null status so EventKit returns every list entry;
 * undated reminders are dropped later. Passing a status would filter completed
 * reminders by completion date instead of due date.
 */
export async function loadDeviceSchedule(
  calendar: ExpoCalendarModule,
  access: AccessSnapshot,
  range: { start: Date; end: Date; dayKeys: string[] },
): Promise<LoadedSchedule> {
  const warnings: string[] = []
  let events: RawEvent[] = []
  let reminders: RawReminder[] = []
  const calendars: NamedCalendar[] = []

  if (access.calendar.status === 'granted') {
    try {
      const eventCalendars = await calendar.getCalendarsAsync(calendar.EntityTypes.EVENT)
      calendars.push(...eventCalendars.map(named))
      const ids = eventCalendars.map((item) => item.id).filter(Boolean)
      if (ids.length > 0) {
        events = await calendar.getEventsAsync(ids, range.start, range.end)
      }
    } catch {
      warnings.push('カレンダー')
    }
  }

  if (access.remindersSupported && access.reminders.status === 'granted') {
    try {
      const reminderCalendars = await calendar.getCalendarsAsync(calendar.EntityTypes.REMINDER)
      calendars.push(...reminderCalendars.map(named))
      const ids = reminderCalendars.map((item) => item.id).filter(Boolean)
      if (ids.length > 0) {
        reminders = await calendar.getRemindersAsync(ids, null, null, null)
      }
    } catch {
      warnings.push('リマインダー')
    }
  }

  const items = assembleSchedule({ events, reminders, calendars, dayKeys: range.dayKeys })
  if (warnings.length > 0 && items.length === 0) {
    return { items, warning: '予定を読み込めませんでした' }
  }
  if (warnings.length > 0) {
    return { items, warning: `${warnings.join('と')}の一部を読み込めませんでした` }
  }
  return { items, warning: null }
}

function named(calendar: DeviceCalendarRecord): NamedCalendar {
  return { id: calendar.id, title: calendar.title || '' }
}

function normalize(permission: PermissionLike): DevicePermission {
  const status = permission.status
  if (status === 'granted' || permission.granted) {
    return { status: 'granted', canAskAgain: permission.canAskAgain !== false }
  }
  if (status === 'denied') {
    return { status: 'denied', canAskAgain: permission.canAskAgain !== false }
  }
  return { status: 'undetermined', canAskAgain: permission.canAskAgain !== false }
}
