import { useCallback, useEffect, useRef, useState } from 'react'
import {
  addOrder,
  removeOrder,
  resetOrders,
  setBudget,
  setQuantity,
  updateOrder,
} from '../lib/orders'
import { loadStateOrEmpty, saveState } from '../lib/storage'
import type { AppState, NewOrder } from '../types/order'

export function useOrders() {
  const [state, setState] = useState<AppState>(loadStateOrEmpty)
  const undoRef = useRef<AppState | null>(null)
  const [canUndo, setCanUndo] = useState(false)

  useEffect(() => {
    saveState(state)
  }, [state])

  const commit = useCallback((updater: (prev: AppState) => AppState) => {
    setState((prev) => {
      undoRef.current = prev
      return updater(prev)
    })
    setCanUndo(true)
  }, [])

  const add = useCallback(
    (item: NewOrder) => {
      commit((prev) => addOrder(prev, item))
    },
    [commit],
  )

  const changeQuantity = useCallback(
    (id: string, quantity: number) => {
      commit((prev) => setQuantity(prev, id, quantity))
    },
    [commit],
  )

  const remove = useCallback(
    (id: string) => {
      commit((prev) => removeOrder(prev, id))
    },
    [commit],
  )

  const update = useCallback(
    (id: string, patch: Partial<NewOrder>) => {
      commit((prev) => updateOrder(prev, id, patch))
    },
    [commit],
  )

  const changeBudget = useCallback(
    (budget: number | null) => {
      commit((prev) => setBudget(prev, budget))
    },
    [commit],
  )

  const reset = useCallback(() => {
    commit((prev) => resetOrders(prev))
  }, [commit])

  const undo = useCallback(() => {
    const previous = undoRef.current
    if (!previous) return
    undoRef.current = null
    setCanUndo(false)
    setState(previous)
  }, [])

  return {
    state,
    add,
    changeQuantity,
    remove,
    update,
    changeBudget,
    reset,
    undo,
    canUndo,
  }
}
