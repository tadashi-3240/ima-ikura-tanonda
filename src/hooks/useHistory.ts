import { useCallback, useEffect, useState } from 'react'
import { appendHistory, loadHistory, removeHistoryBill, saveHistory } from '../lib/history'
import type { AppState, SavedBill } from '../types/order'

export function useHistory() {
  const [bills, setBills] = useState<SavedBill[]>(loadHistory)

  useEffect(() => {
    saveHistory(bills)
  }, [bills])

  const archive = useCallback((state: Pick<AppState, 'orders' | 'budget' | 'placeName'>) => {
    if (state.orders.length === 0) return
    setBills((prev) => appendHistory(prev, state))
  }, [])

  const remove = useCallback((id: string) => {
    setBills((prev) => removeHistoryBill(prev, id))
  }, [])

  return { bills, archive, remove }
}
