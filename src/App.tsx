import { useEffect, useRef, useState } from 'react'
import { AddOrder } from './components/AddOrder'
import { BudgetPanel } from './components/BudgetPanel'
import { HistoryScreen } from './components/HistoryScreen'
import { OpeningCapture } from './components/OpeningCapture'
import { OrderList } from './components/OrderList'
import { PlacePicker } from './components/PlacePicker'
import { TotalDisplay } from './components/TotalDisplay'
import { useHistory } from './hooks/useHistory'
import { useOrders } from './hooks/useOrders'
import { grandTotal } from './lib/money'

type Phase = 'bulk' | 'live' | 'history'

export default function App() {
  const {
    state,
    add,
    addMany,
    changeQuantity,
    remove,
    update,
    changeBudget,
    changePlaceName,
    reset,
    undo,
    canUndo,
  } = useOrders()
  const { bills, archive, remove: removeBill } = useHistory()
  const [confirmReset, setConfirmReset] = useState(false)
  const [editingPlace, setEditingPlace] = useState(false)
  const [phase, setPhase] = useState<Phase>(state.orders.length > 0 ? 'live' : 'bulk')
  const [returnPhase, setReturnPhase] = useState<Exclude<Phase, 'history'>>('bulk')
  const [captureResetKey, setCaptureResetKey] = useState(0)
  const scrollerRef = useRef<HTMLDivElement>(null)
  const total = grandTotal(state.orders)
  const compactTotal = state.orders.length > 2
  const lastOrder = state.orders.at(-1)

  useEffect(() => {
    const root = scrollerRef.current
    if (!root || !lastOrder) return
    root.scrollTo({ top: root.scrollHeight })
  }, [lastOrder?.id, lastOrder?.quantity, state.orders.length])

  const resetAll = () => {
    archive(state)
    reset()
    setEditingPlace(false)
    setCaptureResetKey((value) => value + 1)
    setPhase('bulk')
    setConfirmReset(false)
  }

  const openHistory = (from: Exclude<Phase, 'history'>) => {
    setReturnPhase(from)
    setPhase('history')
  }

  const resetButton = (
    <button
      type="button"
      className="absolute right-4 top-5 z-10 h-11 rounded-xl border border-line px-3 text-sm"
      onClick={() => setConfirmReset(true)}
    >
      リセット
    </button>
  )

  const historyButton = (from: Exclude<Phase, 'history'>) => (
    <button
      type="button"
      className="absolute left-4 top-5 z-10 h-11 rounded-xl border border-line px-3 text-sm"
      onClick={() => openHistory(from)}
    >
      履歴
    </button>
  )

  return (
    <>
      {phase === 'bulk' ? (
        <OpeningCapture
          key={captureResetKey}
          placeName={state.placeName}
          onPlaceChange={changePlaceName}
          resetButton={
            <>
              {historyButton('bulk')}
              {resetButton}
            </>
          }
          onParsed={(items) => {
            addMany(items)
            setPhase('live')
          }}
          onSkip={() => setPhase('live')}
        />
      ) : null}

      {phase === 'live' ? (
        <div className="mx-auto flex h-dvh w-full max-w-3xl flex-col overflow-hidden bg-bg">
          <div className="shrink-0 border-b border-line/50 bg-bg pt-safe">
            <header className={`relative px-4 text-center ${compactTotal ? 'pt-2' : 'pt-4'}`}>
              <button
                type="button"
                className="absolute left-4 top-5 z-10 h-11 rounded-xl px-3 text-sm text-muted disabled:opacity-30"
                disabled={!canUndo}
                onClick={undo}
              >
                元に戻す
              </button>
              {resetButton}
              <h1
                className={`px-16 font-bold tracking-wide ${
                  compactTotal ? 'text-base sm:text-lg' : 'text-2xl sm:text-3xl'
                }`}
              >
                今いくら頼んだ？
              </h1>
              <button
                type="button"
                className="mt-1 text-sm text-muted underline"
                onClick={() => setEditingPlace(true)}
              >
                {state.placeName ?? '店名を設定'}
              </button>
              {compactTotal ? null : (
                <p className="mt-1 text-sm text-muted">注文するたび、合計がわかる。</p>
              )}
            </header>
            <TotalDisplay total={total} compact={compactTotal} />
            <div className="flex justify-center pb-2">
              <button
                type="button"
                className="text-sm text-muted underline"
                onClick={() => openHistory('live')}
              >
                履歴を見る
              </button>
            </div>
          </div>

          <div ref={scrollerRef} className="min-h-0 flex-1 overflow-y-auto pb-3">
            <BudgetPanel budget={state.budget} total={total} onChange={changeBudget} />

            <OrderList
              orders={state.orders}
              onQuantity={changeQuantity}
              onUpdate={update}
              onRemove={remove}
            />
          </div>

          <AddOrder onAdd={add} />
        </div>
      ) : null}

      {phase === 'history' ? (
        <HistoryScreen
          bills={bills}
          onBack={() => setPhase(returnPhase)}
          onRemove={removeBill}
        />
      ) : null}

      {editingPlace && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 p-4 sm:items-center">
          <div className="w-full max-w-md space-y-3 rounded-3xl border border-line bg-surface p-5">
            <PlacePicker
              value={state.placeName}
              onChange={changePlaceName}
              autoSearch={!state.placeName}
            />
            <button
              type="button"
              className="h-12 w-full rounded-2xl border border-line"
              onClick={() => setEditingPlace(false)}
            >
              閉じる
            </button>
          </div>
        </div>
      )}

      {confirmReset && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-6">
          <div className="w-full max-w-sm rounded-3xl border border-line bg-surface p-5 text-center">
            <p className="text-lg font-bold">
              {state.orders.length > 0
                ? 'この注文を履歴に残して、新しい会計を始めますか？'
                : '新しい会計を始めますか？'}
            </p>
            {state.orders.length > 0 && state.placeName ? (
              <p className="mt-2 text-sm text-muted">{state.placeName}</p>
            ) : null}
            <div className="mt-5 flex flex-col gap-2">
              <button
                type="button"
                className="h-14 rounded-2xl bg-danger text-lg font-bold text-bg"
                onClick={resetAll}
              >
                {state.orders.length > 0 ? '履歴に残してリセット' : 'リセットする'}
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
    </>
  )
}
