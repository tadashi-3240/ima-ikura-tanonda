import { useMemo, useState } from 'react'
import { Linking, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { useDeviceSchedule } from '../hooks/useDeviceSchedule'
import {
  copy,
  dayMark,
  inMonth,
  isSameDay,
  itemsOnDay,
  nextLabel,
  previousLabel,
  rangeTitle,
  scheduleAccess,
  shiftAnchor,
  type ScheduleItem,
  type ViewMode,
} from '../lib/scheduleModel'
import { todayTokyo, weekdayJa, ymdKey, type Ymd } from '../lib/tokyoDate'

const colors = {
  bg: '#140e0c',
  surface: '#1c1410',
  card: '#271c17',
  line: '#3d2c26',
  gold: '#f5c518',
  ink: '#f8f1e8',
  muted: '#b7a79a',
  danger: '#ff7a70',
}

const WEEKDAYS = ['月', '火', '水', '木', '金', '土', '日']

export default function ScheduleScreen() {
  const [mode, setMode] = useState<ViewMode>('month')
  const [anchor, setAnchor] = useState<Ymd>(() => todayTokyo())
  const today = todayTokyo()
  const schedule = useDeviceSchedule(anchor, mode)
  const access = scheduleAccess({
    calendar: schedule.access.calendar.status,
    reminders: schedule.access.reminders.status,
    canAskCalendarAgain: schedule.access.calendar.canAskAgain,
    canAskRemindersAgain: schedule.access.reminders.canAskAgain,
    remindersSupported: schedule.access.remindersSupported,
  })

  const openSettings = () => {
    Linking.openSettings().catch(() => undefined)
  }

  const onBanner = () => {
    if (access.banner?.action === 'settings') openSettings()
    else void schedule.request()
  }

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <View style={styles.header}>
        <View>
          <Text style={styles.title}>{copy.title}</Text>
          <Text style={styles.zone}>{copy.zone}</Text>
        </View>
        <Pressable onPress={schedule.reload} hitSlop={8}>
          <Text style={styles.link}>{copy.refresh}</Text>
        </Pressable>
      </View>

      {!schedule.checked ? (
        <Text style={styles.empty}>{copy.loading}</Text>
      ) : access.blocker ? (
        <PermissionGate
          blocker={access.blocker}
          remindersSupported={schedule.access.remindersSupported}
          canAskAgain={
            schedule.access.calendar.canAskAgain || schedule.access.reminders.canAskAgain
          }
          onRequest={() => void schedule.request()}
          onSettings={openSettings}
        />
      ) : (
        <>
          <View style={styles.segment}>
            {(['month', 'week', 'day'] as const).map((value) => {
              const selected = mode === value
              const label = value === 'month' ? copy.month : value === 'week' ? copy.week : copy.day
              return (
                <Pressable
                  key={value}
                  onPress={() => setMode(value)}
                  style={[styles.segmentBtn, selected && styles.segmentOn]}
                  accessibilityRole="button"
                  accessibilityState={{ selected }}
                >
                  <Text style={[styles.segmentText, selected && styles.segmentTextOn]}>{label}</Text>
                </Pressable>
              )
            })}
          </View>
          <View style={styles.nav}>
            <Pressable
              onPress={() => setAnchor((current) => shiftAnchor(current, mode, -1))}
              style={styles.navBtn}
              accessibilityLabel={previousLabel(mode)}
            >
              <Text style={styles.navText}>‹</Text>
            </Pressable>
            <Text style={styles.range}>{rangeTitle(anchor, mode)}</Text>
            <Pressable
              onPress={() => setAnchor((current) => shiftAnchor(current, mode, 1))}
              style={styles.navBtn}
              accessibilityLabel={nextLabel(mode)}
            >
              <Text style={styles.navText}>›</Text>
            </Pressable>
            <Pressable onPress={() => setAnchor(todayTokyo())} style={styles.todayBtn}>
              <Text style={styles.todayText}>{copy.today}</Text>
            </Pressable>
          </View>

          {access.banner && access.banner.text !== copy.iphoneReminders ? (
            <Pressable onPress={onBanner} style={styles.banner}>
              <Text style={styles.bannerText}>{access.banner.text}</Text>
              <Text style={styles.link}>
                {access.banner.action === 'settings' ? copy.openSettings : copy.allow}
              </Text>
            </Pressable>
          ) : null}
          {access.banner?.text === copy.iphoneReminders ? (
            <Text style={styles.note}>{copy.iphoneReminders}</Text>
          ) : null}

          {mode === 'month' ? (
            <MonthBody
              anchor={anchor}
              today={today}
              days={schedule.range.days}
              items={schedule.items}
              loading={schedule.loading}
              warning={schedule.warning}
              onSelect={setAnchor}
              onRetry={schedule.reload}
            />
          ) : mode === 'week' ? (
            <WeekBody
              days={schedule.range.days}
              anchor={anchor}
              today={today}
              items={schedule.items}
              loading={schedule.loading}
              warning={schedule.warning}
              onSelect={setAnchor}
              onRetry={schedule.reload}
            />
          ) : (
            <ItemList
              items={itemsOnDay(schedule.items, ymdKey(anchor))}
              loading={schedule.loading}
              warning={schedule.warning}
              onRetry={schedule.reload}
            />
          )}
        </>
      )}
    </SafeAreaView>
  )
}

function PermissionGate({
  blocker,
  remindersSupported,
  canAskAgain,
  onRequest,
  onSettings,
}: {
  blocker: 'need' | 'denied' | 'unsupported'
  remindersSupported: boolean
  canAskAgain: boolean
  onRequest: () => void
  onSettings: () => void
}) {
  const title =
    blocker === 'unsupported'
      ? copy.unsupportedTitle
      : blocker === 'denied'
        ? copy.deniedTitle
        : remindersSupported
          ? copy.needTitle
          : copy.androidNeedTitle
  const body =
    blocker === 'unsupported'
      ? copy.unsupportedBody
      : blocker === 'denied'
        ? remindersSupported
          ? copy.deniedBody
          : copy.androidDeniedBody
        : remindersSupported
          ? copy.needBody
          : copy.androidNeedBody

  return (
    <View style={styles.gate}>
      <Text style={styles.gateTitle}>{title}</Text>
      <Text style={styles.gateBody}>{body}</Text>
      {blocker === 'unsupported' ? null : blocker === 'denied' && !canAskAgain ? (
        <Pressable style={styles.goldBtn} onPress={onSettings}>
          <Text style={styles.goldBtnText}>{copy.openSettings}</Text>
        </Pressable>
      ) : (
        <Pressable style={styles.goldBtn} onPress={onRequest} testID="schedule-allow">
          <Text style={styles.goldBtnText}>{blocker === 'denied' ? copy.allowAgain : copy.allow}</Text>
        </Pressable>
      )}
      {blocker === 'denied' && canAskAgain ? (
        <Pressable onPress={onSettings}>
          <Text style={styles.linkCenter}>{copy.openSettings}</Text>
        </Pressable>
      ) : null}
    </View>
  )
}

function MonthBody({
  anchor,
  today,
  days,
  items,
  loading,
  warning,
  onSelect,
  onRetry,
}: {
  anchor: Ymd
  today: Ymd
  days: Ymd[]
  items: ScheduleItem[]
  loading: boolean
  warning: string | null
  onSelect: (day: Ymd) => void
  onRetry: () => void
}) {
  const selectedKey = ymdKey(anchor)
  const list = useMemo(() => itemsOnDay(items, selectedKey), [items, selectedKey])
  return (
    <View style={styles.flex}>
      <View style={styles.weekHeader}>
        {WEEKDAYS.map((label) => (
          <Text key={label} style={styles.weekLabel}>
            {label}
          </Text>
        ))}
      </View>
      <View style={styles.grid}>
        {days.map((day) => {
          const key = ymdKey(day)
          const selected = isSameDay(day, anchor)
          const isToday = isSameDay(day, today)
          const mark = dayMark(items, key)
          return (
            <Pressable
              key={key}
              onPress={() => onSelect(day)}
              style={[styles.cell, selected && styles.cellOn, isToday && !selected && styles.cellToday]}
              accessibilityLabel={`${day.month}月${day.day}日`}
            >
              <Text
                style={[
                  styles.cellText,
                  !inMonth(day, anchor.year, anchor.month) && styles.cellMuted,
                  selected && styles.cellTextOn,
                ]}
              >
                {day.day}
              </Text>
              {mark ? (
                <View style={[styles.dot, mark.reminders > 0 ? styles.dotReminder : styles.dotEvent]} />
              ) : (
                <View style={styles.dotSpacer} />
              )}
            </Pressable>
          )
        })}
      </View>
      <Text style={styles.dayHeading}>{formatHeading(anchor)}</Text>
      <ItemList items={list} loading={loading} warning={warning} onRetry={onRetry} />
    </View>
  )
}

function WeekBody({
  days,
  anchor,
  today,
  items,
  loading,
  warning,
  onSelect,
  onRetry,
}: {
  days: Ymd[]
  anchor: Ymd
  today: Ymd
  items: ScheduleItem[]
  loading: boolean
  warning: string | null
  onSelect: (day: Ymd) => void
  onRetry: () => void
}) {
  return (
    <ScrollView style={styles.flex} contentContainerStyle={styles.listContent}>
      {warning ? <Warning warning={warning} onRetry={onRetry} /> : null}
      {loading && items.length === 0 ? <Text style={styles.empty}>{copy.loading}</Text> : null}
      {loading && items.length === 0
        ? null
        : days.map((day) => {
            const key = ymdKey(day)
            const list = itemsOnDay(items, key)
            const selected = isSameDay(day, anchor)
            return (
              <View key={key} style={styles.weekSection}>
                <Pressable onPress={() => onSelect(day)} style={styles.weekDayBtn}>
                  <Text
                    style={[
                      styles.weekDayText,
                      selected && styles.weekDayOn,
                      isSameDay(day, today) && styles.todayMark,
                    ]}
                  >
                    {weekdayJa(day)} {day.day}
                  </Text>
                </Pressable>
                {list.length === 0 ? (
                  <Text style={styles.weekEmpty}>{copy.emptyDay}</Text>
                ) : (
                  list.map((item) => <ItemRow key={`${item.id}-${key}`} item={item} />)
                )}
              </View>
            )
          })}
    </ScrollView>
  )
}

function ItemList({
  items,
  loading,
  warning,
  onRetry,
}: {
  items: ScheduleItem[]
  loading: boolean
  warning: string | null
  onRetry: () => void
}) {
  return (
    <ScrollView style={styles.flex} contentContainerStyle={styles.listContent}>
      {warning ? <Warning warning={warning} onRetry={onRetry} /> : null}
      {loading && items.length === 0 ? (
        <Text style={styles.empty}>{copy.loading}</Text>
      ) : items.length === 0 ? (
        <Text style={styles.empty}>{copy.emptyDay}</Text>
      ) : (
        items.map((item) => <ItemRow key={item.id} item={item} />)
      )}
    </ScrollView>
  )
}

function Warning({ warning, onRetry }: { warning: string; onRetry: () => void }) {
  return (
    <View style={styles.warningBox}>
      <Text style={styles.warning}>{warning}</Text>
      <Pressable onPress={onRetry}>
        <Text style={styles.link}>{copy.retry}</Text>
      </Pressable>
    </View>
  )
}

function ItemRow({ item }: { item: ScheduleItem }) {
  const kind = item.kind === 'reminder' ? copy.reminder : copy.event
  return (
    <View style={[styles.item, item.kind === 'reminder' ? styles.itemReminder : styles.itemEvent, item.completed && styles.itemDone]}>
      <Text style={styles.itemMeta}>
        {item.timeLabel} · {kind}
        {item.completed ? ` · ${copy.done}` : ''}
      </Text>
      <Text style={styles.itemTitle}>{item.title}</Text>
      <Text style={styles.itemCalendar}>{item.calendarName}</Text>
    </View>
  )
}

function formatHeading(day: Ymd): string {
  return `${day.month}月${day.day}日（${weekdayJa(day)}）`
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  flex: { flex: 1 },
  header: {
    paddingHorizontal: 16,
    paddingTop: 4,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
  },
  title: { color: colors.ink, fontSize: 26, fontWeight: '700' },
  zone: { color: colors.muted, marginTop: 2 },
  link: { color: colors.gold, fontWeight: '700' },
  linkCenter: { color: colors.gold, fontWeight: '700', textAlign: 'center', marginTop: 14 },
  segment: {
    marginTop: 12,
    marginHorizontal: 16,
    flexDirection: 'row',
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.line,
    padding: 4,
  },
  segmentBtn: { flex: 1, height: 36, borderRadius: 8, alignItems: 'center', justifyContent: 'center' },
  segmentOn: { backgroundColor: colors.gold },
  segmentText: { color: colors.muted, fontWeight: '700' },
  segmentTextOn: { color: colors.bg },
  nav: {
    marginTop: 12,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  navBtn: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  navText: { color: colors.ink, fontSize: 28, fontWeight: '600' },
  range: { flex: 1, color: colors.ink, fontSize: 16, fontWeight: '700', textAlign: 'center' },
  todayBtn: {
    borderWidth: 1,
    borderColor: colors.line,
    borderRadius: 12,
    paddingHorizontal: 12,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  todayText: { color: colors.ink, fontWeight: '700' },
  banner: {
    marginTop: 10,
    marginHorizontal: 16,
    backgroundColor: colors.card,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.line,
    padding: 12,
    gap: 6,
  },
  bannerText: { color: colors.ink, lineHeight: 20 },
  note: { marginTop: 8, marginHorizontal: 16, color: colors.muted },
  weekHeader: { flexDirection: 'row', paddingHorizontal: 8, marginTop: 8 },
  weekLabel: { width: `${100 / 7}%`, textAlign: 'center', color: colors.muted, fontSize: 12 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', paddingHorizontal: 8 },
  cell: { width: `${100 / 7}%`, height: 44, alignItems: 'center', justifyContent: 'center' },
  cellOn: { backgroundColor: colors.gold, borderRadius: 12 },
  cellToday: { borderWidth: 1, borderColor: colors.gold, borderRadius: 12 },
  cellText: { color: colors.ink, fontWeight: '600' },
  cellMuted: { color: colors.muted },
  cellTextOn: { color: colors.bg },
  dot: { width: 6, height: 6, borderRadius: 3, marginTop: 3 },
  dotReminder: { backgroundColor: colors.gold },
  dotEvent: { backgroundColor: colors.muted },
  dotSpacer: { height: 6, marginTop: 3 },
  dayHeading: {
    marginTop: 8,
    paddingHorizontal: 16,
    color: colors.ink,
    fontSize: 16,
    fontWeight: '700',
  },
  listContent: { paddingHorizontal: 16, paddingBottom: 24 },
  empty: { marginTop: 28, color: colors.muted, textAlign: 'center', lineHeight: 22 },
  item: {
    marginTop: 10,
    backgroundColor: colors.card,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.line,
    padding: 14,
    borderLeftWidth: 4,
  },
  itemReminder: { borderLeftColor: colors.gold },
  itemEvent: { borderLeftColor: colors.muted },
  itemDone: { opacity: 0.45 },
  itemMeta: { color: colors.muted, fontSize: 13 },
  itemTitle: { marginTop: 4, color: colors.ink, fontSize: 18, fontWeight: '700' },
  itemCalendar: { marginTop: 4, color: colors.muted },
  gate: { flex: 1, justifyContent: 'center', paddingHorizontal: 24 },
  gateTitle: { color: colors.ink, fontSize: 22, fontWeight: '700', textAlign: 'center' },
  gateBody: { marginTop: 12, color: colors.muted, lineHeight: 22, textAlign: 'center' },
  goldBtn: {
    marginTop: 20,
    height: 56,
    borderRadius: 16,
    backgroundColor: colors.gold,
    alignItems: 'center',
    justifyContent: 'center',
  },
  goldBtnText: { color: colors.bg, fontSize: 18, fontWeight: '800' },
  warningBox: { marginTop: 12, gap: 6 },
  warning: { color: colors.danger, lineHeight: 20 },
  weekSection: { marginTop: 14 },
  weekDayBtn: { paddingVertical: 4 },
  weekDayText: { color: colors.ink, fontWeight: '700', fontSize: 16 },
  weekDayOn: { color: colors.gold },
  todayMark: { textDecorationLine: 'underline' },
  weekEmpty: { marginTop: 4, color: colors.muted },
})
