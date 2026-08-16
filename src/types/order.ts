export type Order = {
  id: string
  name: string
  unitPrice: number
  quantity: number
}

export type NewOrder = {
  name: string
  unitPrice: number
  quantity: number
}

export type AppState = {
  orders: Order[]
  budget: number | null
}

export type ParsedOrder = {
  name: string
  unitPrice: number
  quantity: number
}
