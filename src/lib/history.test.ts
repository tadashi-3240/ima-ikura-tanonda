import { beforeEach, describe, expect, it } from 'vitest'
import {
  HISTORY_KEY,
  appendHistory,
  loadHistory,
  removeHistoryBill,
  saveHistory,
} from './history'

describe('会計履歴', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('リセット時に注文があれば履歴の先頭へ残す', () => {
    const next = appendHistory([], {
      orders: [{ id: '1', name: 'ビール', unitPrice: 650, quantity: 2 }],
      budget: null,
    })
    expect(next).toHaveLength(1)
    expect(next[0]?.orders[0]?.name).toBe('ビール')
    saveHistory(next)
    expect(loadHistory()).toHaveLength(1)
    expect(localStorage.getItem(HISTORY_KEY)).toBeTruthy()
  })

  it('空の注文は履歴に残さない', () => {
    expect(appendHistory([], { orders: [], budget: null })).toEqual([])
  })

  it('履歴を削除できる', () => {
    const bills = appendHistory([], {
      orders: [{ id: '1', name: '餃子', unitPrice: 1100, quantity: 1 }],
      budget: null,
    })
    expect(removeHistoryBill(bills, bills[0]!.id)).toEqual([])
  })
})
