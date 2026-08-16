import { useState } from 'react'
import { formatYen, lineSubtotal } from '../lib/money'
import type { NewOrder, Order } from '../types/order'
import { ManualForm } from './ManualForm'
import { QuantityStepper } from './QuantityStepper'

type Props = {
  orders: Order[]
  onQuantity: (id: string, quantity: number) => void
  onUpdate: (id: string, patch: Partial<NewOrder>) => void
  onRemove: (id: string) => void
}

export function OrderList({ orders, onQuantity, onUpdate, onRemove }: Props) {
  const [editingId, setEditingId] = useState<string | null>(null)
  const editing = orders.find((order) => order.id === editingId) ?? null

  if (orders.length === 0) {
    return (
      <p className="px-6 py-10 text-center text-muted">
        料理名と金額を入れると、ここに注文が表示されます。
      </p>
    )
  }

  return (
    <>
      <div className="hidden md:block px-4">
        <table className="w-full border-collapse text-left">
          <thead>
            <tr className="border-b border-line text-sm text-muted">
              <th className="py-2 font-medium">品物</th>
              <th className="py-2 text-right font-medium">単価</th>
              <th className="py-2 text-right font-medium">数量</th>
              <th className="py-2 text-right font-medium">小計</th>
              <th className="py-2 font-medium" />
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.id} className="border-b border-line/70">
                <td className="py-3 font-semibold">{order.name}</td>
                <td className="py-3 text-right tabular-nums">{formatYen(order.unitPrice)}</td>
                <td className="py-3">
                  <div className="flex justify-end">
                    <QuantityStepper
                      value={order.quantity}
                      onChange={(quantity) => onQuantity(order.id, quantity)}
                    />
                  </div>
                </td>
                <td className="py-3 text-right font-bold tabular-nums text-gold">
                  {formatYen(lineSubtotal(order.unitPrice, order.quantity))}
                </td>
                <td className="py-3 pl-3 text-right">
                  <button
                    type="button"
                    className="text-sm text-muted underline"
                    onClick={() => setEditingId(order.id)}
                  >
                    編集
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <ul className="space-y-3 px-4 md:hidden">
        {orders.map((order) => (
          <li key={order.id} className="rounded-2xl border border-line bg-card p-4">
            <div className="flex items-start justify-between gap-3">
              <p className="text-lg font-bold leading-tight">{order.name}</p>
              <button
                type="button"
                className="shrink-0 text-sm text-muted underline"
                onClick={() => setEditingId(order.id)}
              >
                編集
              </button>
            </div>
            <p className="mt-1 text-muted tabular-nums">
              {formatYen(order.unitPrice)} × {order.quantity}
            </p>
            <div className="mt-3 flex items-center justify-between gap-3">
              <p className="text-2xl font-bold text-gold tabular-nums">
                {formatYen(lineSubtotal(order.unitPrice, order.quantity))}
              </p>
              <QuantityStepper
                value={order.quantity}
                onChange={(quantity) => onQuantity(order.id, quantity)}
              />
            </div>
          </li>
        ))}
      </ul>

      {editing && (
        <div className="fixed inset-0 z-40 flex items-end justify-center bg-black/55 p-4 sm:items-center">
          <div className="w-full max-w-md rounded-3xl border border-line bg-surface p-5">
            <h2 className="mb-4 text-lg font-bold">注文を編集</h2>
            <ManualForm
              key={editing.id}
              initial={editing}
              submitLabel="保存"
              onSubmit={(item) => {
                onUpdate(editing.id, item)
                setEditingId(null)
              }}
              onCancel={() => setEditingId(null)}
            />
            <button
              type="button"
              className="mt-6 h-12 w-full rounded-2xl border border-danger/40 text-danger"
              onClick={() => {
                onRemove(editing.id)
                setEditingId(null)
              }}
            >
              この注文を削除
            </button>
          </div>
        </div>
      )}
    </>
  )
}
