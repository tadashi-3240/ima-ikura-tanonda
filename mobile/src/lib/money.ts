import type { Order } from '../types/order'

export function lineSubtotal(unitPrice: number, quantity: number): number {
  return unitPrice * quantity
}

export function grandTotal(orders: Pick<Order, 'unitPrice' | 'quantity'>[]): number {
  let total = 0
  for (const order of orders) {
    total += lineSubtotal(order.unitPrice, order.quantity)
  }
  return total
}

export function formatYen(amount: number): string {
  return `${amount.toLocaleString('ja-JP')}円`
}

export function remainingBudget(budget: number | null, total: number): number | null {
  if (budget === null) return null
  return budget - total
}

export function parseYenInput(input: string): number | null {
  const text = input.normalize('NFKC').replace(/[,，\s円]/g, '')
  if (!/^[0-9]+$/.test(text)) return null
  const amount = Number.parseInt(text, 10)
  return Number.isFinite(amount) ? amount : null
}
