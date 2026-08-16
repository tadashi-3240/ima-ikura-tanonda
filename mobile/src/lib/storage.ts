import AsyncStorage from '@react-native-async-storage/async-storage'
import type { AppState, Order } from '../types/order'
import { emptyState } from './orders'

export const STORAGE_KEY = 'ima-ikura-tanonda:v1'

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

function isAppState(value: unknown): value is AppState {
  if (typeof value !== 'object' || value === null) return false
  const state = value as Record<string, unknown>
  const budgetOk =
    state.budget === null ||
    (typeof state.budget === 'number' && Number.isInteger(state.budget) && state.budget >= 0)
  return Array.isArray(state.orders) && state.orders.every(isOrder) && budgetOk
}

export async function loadState(): Promise<AppState | null> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const parsed: unknown = JSON.parse(raw)
    if (!isAppState(parsed)) return null
    return parsed
  } catch {
    return null
  }
}

export async function saveState(state: AppState): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(state))
}

export async function loadStateOrEmpty(): Promise<AppState> {
  return (await loadState()) ?? emptyState()
}
