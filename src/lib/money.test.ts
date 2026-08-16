import { describe, expect, it } from 'vitest'
import { formatYen, grandTotal, lineSubtotal, remainingBudget } from './money'
import { sampleOrders, SAMPLE_TOTAL } from './sampleData'

describe('金額計算', () => {
  it('1750 × 2 = 3500になる', () => {
    expect(lineSubtotal(1750, 2)).toBe(3500)
  })

  it('600 × 2 = 1200になる', () => {
    expect(lineSubtotal(600, 2)).toBe(1200)
  })

  it('サンプルデータの総額が14,550円になる', () => {
    expect(grandTotal(sampleOrders())).toBe(SAMPLE_TOTAL)
    expect(formatYen(SAMPLE_TOTAL)).toBe('14,550円')
  })

  it('日本円は整数のまま扱う', () => {
    expect(Number.isInteger(lineSubtotal(1750, 2))).toBe(true)
    expect(remainingBudget(15000, 14550)).toBe(450)
    expect(remainingBudget(15000, 16200)).toBe(-1200)
    expect(remainingBudget(null, 14550)).toBeNull()
  })
})
