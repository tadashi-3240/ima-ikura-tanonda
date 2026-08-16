import type { NewOrder, Order } from '../types/order'

export const SAMPLE_ITEMS: NewOrder[] = [
  { name: '本日の特選牛盛り', unitPrice: 4250, quantity: 1 },
  { name: 'ローストホース', unitPrice: 1750, quantity: 2 },
  { name: 'うまうま餃子', unitPrice: 1100, quantity: 2 },
  { name: 'アスパラの桜肉巻き', unitPrice: 1700, quantity: 1 },
  { name: '馬のなめろう', unitPrice: 850, quantity: 1 },
  { name: 'ご飯', unitPrice: 600, quantity: 2 },
  { name: 'アスパラ肉', unitPrice: 850, quantity: 1 },
]

export const SAMPLE_TOTAL = 14550

export function sampleOrders(): Order[] {
  return SAMPLE_ITEMS.map((item, index) => ({
    ...item,
    id: `sample-${index}`,
  }))
}
