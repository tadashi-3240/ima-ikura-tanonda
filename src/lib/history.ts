import type { AppState, Order, SavedBill } from '../types/order'

export const HISTORY_KEY = 'ima-ikura-tanonda:history:v1'
export const HISTORY_LIMIT = 50

function isOrder(value: unknown): value is Order {
  if (typeof value !== 'object' || value === null) return false
  const item = value as Record<string, unknown>
  return (
    typeof item.id === 'string' &&
    typeof item.name === 'string' &&
    typeof item.unitPrice === 'number' &&
    Number.isInteger(item.unitPrice) &&
    typeof item.quantity === 'number' &&
    Number.isInteger(item.quantity) &&
    item.quantity >= 1
  )
}

function isSavedBill(value: unknown): value is SavedBill {
  if (typeof value !== 'object' || value === null) return false
  const bill = value as Record<string, unknown>
  const budgetOk =
    bill.budget === null ||
    (typeof bill.budget === 'number' && Number.isInteger(bill.budget) && bill.budget >= 0)
  return (
    typeof bill.id === 'string' &&
    typeof bill.savedAt === 'number' &&
    Number.isFinite(bill.savedAt) &&
    Array.isArray(bill.orders) &&
    bill.orders.every(isOrder) &&
    budgetOk
  )
}

export function loadHistory(): SavedBill[] {
  try {
    const raw = localStorage.getItem(HISTORY_KEY)
    if (!raw) return []
    const parsed: unknown = JSON.parse(raw)
    if (!Array.isArray(parsed)) return []
    return parsed.filter(isSavedBill)
  } catch {
    return []
  }
}

export function saveHistory(bills: SavedBill[]): void {
  localStorage.setItem(HISTORY_KEY, JSON.stringify(bills.slice(0, HISTORY_LIMIT)))
}

export function createSavedBill(state: Pick<AppState, 'orders' | 'budget'>, savedAt = Date.now()): SavedBill {
  return {
    id: crypto.randomUUID(),
    savedAt,
    orders: state.orders.map((order) => ({ ...order })),
    budget: state.budget,
  }
}

/** 先頭が新しい。注文が空なら追加しない。 */
export function appendHistory(bills: SavedBill[], state: Pick<AppState, 'orders' | 'budget'>): SavedBill[] {
  if (state.orders.length === 0) return bills
  return [createSavedBill(state), ...bills].slice(0, HISTORY_LIMIT)
}

export function removeHistoryBill(bills: SavedBill[], id: string): SavedBill[] {
  return bills.filter((bill) => bill.id !== id)
}

export function formatSavedAt(savedAt: number): string {
  return new Intl.DateTimeFormat('ja-JP', {
    month: 'numeric',
    day: 'numeric',
    weekday: 'short',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(savedAt))
}
