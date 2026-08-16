import { beforeEach, describe, expect, it } from 'vitest'
import { addOrder, emptyState } from './orders'
import { SAMPLE_ITEMS, SAMPLE_TOTAL } from './sampleData'
import { grandTotal } from './money'
import { loadState, saveState, STORAGE_KEY } from './storage'

describe('localStorage', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('localStorageから正しく復元される', () => {
    let state = emptyState()
    for (const item of SAMPLE_ITEMS) {
      state = addOrder(state, item)
    }
    state = { ...state, budget: 15000 }
    saveState(state)

    const raw = localStorage.getItem(STORAGE_KEY)
    expect(raw).toBeTruthy()

    const restored = loadState()
    expect(restored).not.toBeNull()
    expect(restored?.budget).toBe(15000)
    expect(restored?.orders).toHaveLength(SAMPLE_ITEMS.length)
    expect(grandTotal(restored?.orders ?? [])).toBe(SAMPLE_TOTAL)
    expect(restored?.orders.map((order) => ({
      name: order.name,
      unitPrice: order.unitPrice,
      quantity: order.quantity,
    }))).toEqual(SAMPLE_ITEMS)
  })
})
