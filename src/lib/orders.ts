import type { AppState, NewOrder, Order } from '../types/order'

export function createOrderId(): string {
  return crypto.randomUUID()
}

export function emptyState(): AppState {
  return { orders: [], budget: null }
}

function sameItem(a: Pick<Order, 'name' | 'unitPrice'>, b: Pick<Order, 'name' | 'unitPrice'>): boolean {
  return a.name === b.name && a.unitPrice === b.unitPrice
}

export function addOrder(state: AppState, incoming: NewOrder): AppState {
  const existing = state.orders.find((order) => sameItem(order, incoming))
  if (existing) {
    return {
      ...state,
      orders: state.orders.map((order) =>
        order.id === existing.id
          ? { ...order, quantity: order.quantity + incoming.quantity }
          : order,
      ),
    }
  }

  const next: Order = {
    id: createOrderId(),
    name: incoming.name,
    unitPrice: incoming.unitPrice,
    quantity: incoming.quantity,
  }

  return { ...state, orders: [...state.orders, next] }
}

export function setQuantity(state: AppState, id: string, quantity: number): AppState {
  const nextQuantity = Math.max(1, quantity)
  return {
    ...state,
    orders: state.orders.map((order) =>
      order.id === id ? { ...order, quantity: nextQuantity } : order,
    ),
  }
}

export function removeOrder(state: AppState, id: string): AppState {
  return { ...state, orders: state.orders.filter((order) => order.id !== id) }
}

export function updateOrder(state: AppState, id: string, patch: Partial<NewOrder>): AppState {
  const current = state.orders.find((order) => order.id === id)
  if (!current) return state

  const nextItem: Order = {
    ...current,
    ...patch,
    quantity: Math.max(1, patch.quantity ?? current.quantity),
  }

  const duplicate = state.orders.find(
    (order) => order.id !== id && sameItem(order, nextItem),
  )

  if (duplicate) {
    return {
      ...state,
      orders: state.orders
        .filter((order) => order.id !== id)
        .map((order) =>
          order.id === duplicate.id
            ? { ...order, quantity: order.quantity + nextItem.quantity }
            : order,
        ),
    }
  }

  return {
    ...state,
    orders: state.orders.map((order) => (order.id === id ? nextItem : order)),
  }
}

export function setBudget(state: AppState, budget: number | null): AppState {
  if (budget === null) return { ...state, budget: null }
  return { ...state, budget: Math.max(0, budget) }
}

export function resetOrders(state: AppState): AppState {
  return { ...state, orders: [] }
}
