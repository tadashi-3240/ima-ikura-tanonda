import { describe, expect, it } from 'vitest'
import { grandTotal, lineSubtotal } from './money'
import { addOrder, emptyState, setQuantity } from './orders'
import { parseOrderText } from './parseOrder'
import { SAMPLE_ITEMS, SAMPLE_TOTAL, sampleOrders } from './sampleData'

describe('注文操作', () => {
  it('同じ商品を追加すると数量が合算される', () => {
    let state = emptyState()
    state = addOrder(state, { name: 'ご飯', unitPrice: 600, quantity: 2 })
    state = addOrder(state, { name: 'ご飯', unitPrice: 600, quantity: 1 })
    expect(state.orders).toHaveLength(1)
    expect(state.orders[0]?.quantity).toBe(3)
    expect(lineSubtotal(state.orders[0]!.unitPrice, state.orders[0]!.quantity)).toBe(1800)
  })

  it('数量変更時に合計が更新される', () => {
    let state = emptyState()
    state = addOrder(state, { name: 'ローストホース', unitPrice: 1750, quantity: 2 })
    expect(grandTotal(state.orders)).toBe(3500)
    const id = state.orders[0]!.id
    state = setQuantity(state, id, 3)
    expect(grandTotal(state.orders)).toBe(5250)
    state = setQuantity(state, id, 1)
    expect(grandTotal(state.orders)).toBe(1750)
  })

  it('サンプルデータの総額が14,550円になる', () => {
    let state = emptyState()
    for (const item of SAMPLE_ITEMS) {
      state = addOrder(state, item)
    }
    expect(grandTotal(state.orders)).toBe(SAMPLE_TOTAL)
    expect(grandTotal(sampleOrders())).toBe(14550)
  })

  it('最終確認の自然文入力で14,550円になる', () => {
    const lines = [
      '本日の特選牛盛り 4250円',
      'ローストホース 1750円を2つ',
      'うまうま餃子 1100円を2つ',
      'アスパラの桜肉巻き 1700円',
      '馬のなめろう 850円',
      'ご飯 600円を2つ',
      'アスパラ肉 850円',
    ]
    let state = emptyState()
    for (const line of lines) {
      const parsed = parseOrderText(line)
      expect(parsed).not.toBeNull()
      state = addOrder(state, parsed!)
    }
    expect(grandTotal(state.orders)).toBe(14550)
  })
})
