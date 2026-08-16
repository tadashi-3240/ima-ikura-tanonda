import { useState } from 'react'
import { AddOrder } from './components/AddOrder'
import { BudgetPanel } from './components/BudgetPanel'
import { OrderList } from './components/OrderList'
import { TotalDisplay } from './components/TotalDisplay'
import { useOrders } from './hooks/useOrders'
import { grandTotal } from './lib/money'

export default function App() {
  const {
    state,
    add,
    changeQuantity,
    remove,
    update,
    changeBudget,
    reset,
    undo,
    canUndo,
  } = useOrders()
  const [confirmReset, setConfirmReset] = useState(false)
  const total = grandTotal(state.orders)

  return (
    <div className="mx-auto min-h-dvh w-full max-w-3xl bg-bg pb-44 pt-safe">
      <header className="px-4 pt-5 text-center">
        <h1 className="text-2xl font-bold tracking-wide sm:text-3xl">今いくら頼んだ？</h1>
        <p className="mt-1 text-sm text-muted">注文するたび、合計がわかる。</p>
      </header>

      <TotalDisplay total={total} />
      <BudgetPanel budget={state.budget} total={total} onChange={changeBudget} />

      <div className="mb-4 flex items-center justify-between px-4">
        <button
          type="button"
          className="h-11 rounded-xl px-3 text-muted disabled:opacity-30"
          disabled={!canUndo}
          onClick={undo}
        >
          元に戻す
        </button>
        <button
          type="button"
          className="h-11 rounded-xl border border-line px-4 text-sm"
          onClick={() => setConfirmReset(true)}
        >
          新しい会計
        </button>
      </div>

      <OrderList
        orders={state.orders}
        onQuantity={changeQuantity}
        onUpdate={update}
        onRemove={remove}
      />

      <AddOrder onAdd={add} />

      {confirmReset && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-6">
          <div className="w-full max-w-sm rounded-3xl border border-line bg-surface p-5 text-center">
            <p className="text-lg font-bold">現在の注文をすべて消去しますか？</p>
            <div className="mt-5 flex flex-col gap-2">
              <button
                type="button"
                className="h-14 rounded-2xl bg-danger text-lg font-bold text-bg"
                onClick={() => {
                  reset()
                  setConfirmReset(false)
                }}
              >
                消去する
              </button>
              <button
                type="button"
                className="h-12 rounded-2xl border border-line"
                onClick={() => setConfirmReset(false)}
              >
                キャンセル
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
