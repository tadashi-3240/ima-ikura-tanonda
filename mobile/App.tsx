import { StatusBar } from 'expo-status-bar'
import { useState } from 'react'
import {
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native'
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context'
import { useOrders } from './src/hooks/useOrders'
import { formatYen, grandTotal, lineSubtotal, parseYenInput, remainingBudget } from './src/lib/money'
import { parseOrderText } from './src/lib/parseOrder'
import type { NewOrder, Order, ParsedOrder } from './src/types/order'

const colors = {
  bg: '#140e0c',
  surface: '#1c1410',
  card: '#271c17',
  line: '#3d2c26',
  gold: '#f5c518',
  ink: '#f8f1e8',
  muted: '#b7a79a',
  danger: '#ff7a70',
  ok: '#8ad48f',
}

export default function App() {
  const {
    ready,
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
  const total = grandTotal(state.orders)
  const remaining = remainingBudget(state.budget, total)

  const [text, setText] = useState('')
  const [error, setError] = useState('')
  const [manual, setManual] = useState(false)
  const [confirm, setConfirm] = useState<ParsedOrder | null>(null)
  const [editing, setEditing] = useState<Order | null>(null)
  const [budgetOpen, setBudgetOpen] = useState(false)
  const [resetOpen, setResetOpen] = useState(false)

  const submitText = () => {
    const parsed = parseOrderText(text)
    if (!parsed) {
      setError('商品名と金額を入力。例: ビール650円を2つ')
      return
    }
    setError('')
    if (!parsed.name) {
      setConfirm(parsed)
      setManual(true)
      return
    }
    add(parsed)
    setText('')
  }

  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.safe} edges={['top']}>
        <StatusBar style="light" />
        <KeyboardAvoidingView
          style={styles.flex}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        >
          <ScrollView
            style={styles.flex}
            contentContainerStyle={styles.scroll}
            keyboardShouldPersistTaps="handled"
          >
            <Text style={styles.title}>今いくら頼んだ？</Text>
            <Text style={styles.tagline}>注文するたび、合計がわかる。</Text>
            <Text style={styles.totalLabel}>現在の合計</Text>
            <Text style={styles.total}>{formatYen(total)}</Text>

            {state.budget === null || remaining === null ? (
              <Pressable onPress={() => setBudgetOpen(true)}>
                <Text style={styles.link}>予算を設定</Text>
              </Pressable>
            ) : (
              <Pressable style={styles.budgetBox} onPress={() => setBudgetOpen(true)}>
                <Text style={styles.muted}>予算 {formatYen(state.budget)}</Text>
                {remaining < 0 ? (
                  <Text style={styles.over}>{formatYen(-remaining)}オーバー</Text>
                ) : (
                  <Text style={styles.ok}>残り {formatYen(remaining)}</Text>
                )}
              </Pressable>
            )}

            <View style={styles.rowBetween}>
              <Pressable onPress={undo} disabled={!canUndo}>
                <Text style={[styles.muted, !canUndo && styles.disabled]}>元に戻す</Text>
              </Pressable>
              <Pressable style={styles.outlineBtn} onPress={() => setResetOpen(true)}>
                <Text style={styles.ink}>新しい会計</Text>
              </Pressable>
            </View>

            {!ready ? (
              <Text style={styles.empty}>読み込み中…</Text>
            ) : state.orders.length === 0 ? (
              <Text style={styles.empty}>料理名と金額を入れると、ここに注文が表示されます。</Text>
            ) : (
              state.orders.map((order) => (
                <View key={order.id} style={styles.card}>
                  <View style={styles.rowBetween}>
                    <Text style={styles.itemName}>{order.name}</Text>
                    <Pressable
                      onPress={() => {
                        setConfirm(null)
                        setEditing(order)
                        setManual(true)
                      }}
                    >
                      <Text style={styles.link}>編集</Text>
                    </Pressable>
                  </View>
                  <Text style={styles.muted}>
                    {formatYen(order.unitPrice)} × {order.quantity}
                  </Text>
                  <View style={[styles.rowBetween, styles.cardBottom]}>
                    <Text style={styles.subtotal}>
                      {formatYen(lineSubtotal(order.unitPrice, order.quantity))}
                    </Text>
                    <QuantityStepper
                      value={order.quantity}
                      onChange={(quantity) => changeQuantity(order.id, quantity)}
                    />
                  </View>
                </View>
              ))
            )}
          </ScrollView>

          <SafeAreaView edges={['bottom']} style={styles.composer}>
            {confirm && !manual ? (
              <ConfirmCard
                parsed={confirm}
                onAdd={() => {
                  if (!confirm.name) {
                    setManual(true)
                    return
                  }
                  add(confirm)
                  setConfirm(null)
                  setText('')
                }}
                onEdit={() => setManual(true)}
              />
            ) : (
              <>
                <View style={styles.inputRow}>
                  <TextInput
                    value={text}
                    onChangeText={(value) => {
                      setText(value)
                      if (error) setError('')
                    }}
                    placeholder="ビール650円を2つ"
                    placeholderTextColor={colors.muted}
                    style={[styles.input, styles.inputFlex]}
                    returnKeyType="done"
                    onSubmitEditing={submitText}
                  />
                </View>
                {error ? <Text style={styles.error}>{error}</Text> : null}
                <Pressable style={styles.addBtn} onPress={submitText}>
                  <Text style={styles.addBtnText}>追加</Text>
                </Pressable>
                <Pressable
                  onPress={() => {
                    setEditing(null)
                    setManual(true)
                  }}
                >
                  <Text style={styles.manualLink}>手入力</Text>
                </Pressable>
              </>
            )}
          </SafeAreaView>
        </KeyboardAvoidingView>

        <ManualModal
          key={editing?.id ?? (manual ? 'manual' : 'closed')}
          visible={manual}
          initial={editing ?? confirm ?? { quantity: 1 }}
          title={editing ? '注文を編集' : '手入力'}
          submitLabel={editing ? '保存' : '追加'}
          onClose={() => {
            setManual(false)
            setConfirm(null)
            setEditing(null)
          }}
          onSubmit={(item) => {
            if (editing) update(editing.id, item)
            else add(item)
            setManual(false)
            setConfirm(null)
            setEditing(null)
            setText('')
          }}
          onDelete={
            editing
              ? () => {
                  remove(editing.id)
                  setManual(false)
                  setEditing(null)
                }
              : undefined
          }
        />

        <BudgetModal
          key={budgetOpen ? `budget-${state.budget ?? 'none'}` : 'budget-closed'}
          visible={budgetOpen}
          budget={state.budget}
          onClose={() => setBudgetOpen(false)}
          onSave={(budget) => {
            changeBudget(budget)
            setBudgetOpen(false)
          }}
        />

        <Modal transparent visible={resetOpen} animationType="fade">
          <View style={styles.overlay}>
            <View style={styles.sheet}>
              <Text style={styles.sheetTitle}>現在の注文をすべて消去しますか？</Text>
              <Pressable
                style={styles.dangerBtn}
                onPress={() => {
                  reset()
                  setResetOpen(false)
                }}
              >
                <Text style={styles.addBtnText}>消去する</Text>
              </Pressable>
              <Pressable style={styles.outlineBtn} onPress={() => setResetOpen(false)}>
                <Text style={styles.ink}>キャンセル</Text>
              </Pressable>
            </View>
          </View>
        </Modal>
      </SafeAreaView>
    </SafeAreaProvider>
  )
}

function QuantityStepper({
  value,
  onChange,
}: {
  value: number
  onChange: (quantity: number) => void
}) {
  return (
    <View style={styles.stepper}>
      <Pressable style={styles.stepBtn} onPress={() => onChange(value - 1)}>
        <Text style={styles.stepText}>−</Text>
      </Pressable>
      <Text style={styles.qty}>{value}</Text>
      <Pressable style={styles.stepBtn} onPress={() => onChange(value + 1)}>
        <Text style={styles.stepText}>＋</Text>
      </Pressable>
    </View>
  )
}

function ConfirmCard({
  parsed,
  onAdd,
  onEdit,
}: {
  parsed: ParsedOrder
  onAdd: () => void
  onEdit: () => void
}) {
  return (
    <View style={styles.confirm}>
      <Text style={styles.itemName}>{parsed.name || '（商品名なし）'}</Text>
      <Text style={styles.muted}>
        {formatYen(parsed.unitPrice)} × {parsed.quantity}
      </Text>
      <Text style={styles.subtotal}>{formatYen(lineSubtotal(parsed.unitPrice, parsed.quantity))}</Text>
      <Pressable style={styles.addBtn} onPress={onAdd}>
        <Text style={styles.addBtnText}>追加する</Text>
      </Pressable>
      <Pressable onPress={onEdit}>
        <Text style={styles.manualLink}>修正</Text>
      </Pressable>
    </View>
  )
}

function ManualModal({
  visible,
  initial,
  title,
  submitLabel,
  onClose,
  onSubmit,
  onDelete,
}: {
  visible: boolean
  initial: Partial<NewOrder>
  title: string
  submitLabel: string
  onClose: () => void
  onSubmit: (item: NewOrder) => void
  onDelete?: () => void
}) {
  const [name, setName] = useState(initial.name ?? '')
  const [price, setPrice] = useState(
    initial.unitPrice != null && initial.unitPrice > 0 ? String(initial.unitPrice) : '',
  )
  const [quantity, setQuantity] = useState(initial.quantity ?? 1)
  const [formError, setFormError] = useState('')

  const save = () => {
    const trimmed = name.trim()
    const unitPrice = parseYenInput(price)
    if (!trimmed) {
      setFormError('商品名を入力してください')
      return
    }
    if (unitPrice === null || unitPrice <= 0) {
      setFormError('単価を入力してください')
      return
    }
    onSubmit({ name: trimmed, unitPrice, quantity: Math.max(1, quantity) })
  }

  return (
    <Modal transparent visible={visible} animationType="slide">
      <View style={styles.overlay}>
        <View style={styles.sheet}>
          <Text style={styles.sheetTitle}>{title}</Text>
          <Text style={styles.label}>商品名</Text>
          <TextInput value={name} onChangeText={setName} style={styles.input} />
          <Text style={styles.label}>単価</Text>
          <TextInput
            value={price}
            onChangeText={setPrice}
            keyboardType="number-pad"
            style={styles.input}
          />
          <Text style={styles.label}>数量</Text>
          <QuantityStepper value={quantity} onChange={(value) => setQuantity(Math.max(1, value))} />
          {formError ? <Text style={styles.error}>{formError}</Text> : null}
          <Pressable style={styles.addBtn} onPress={save}>
            <Text style={styles.addBtnText}>{submitLabel}</Text>
          </Pressable>
          <Pressable style={styles.outlineBtn} onPress={onClose}>
            <Text style={styles.ink}>戻る</Text>
          </Pressable>
          {onDelete ? (
            <Pressable style={styles.deleteBtn} onPress={onDelete}>
              <Text style={styles.dangerText}>この注文を削除</Text>
            </Pressable>
          ) : null}
        </View>
      </View>
    </Modal>
  )
}

function BudgetModal({
  visible,
  budget,
  onClose,
  onSave,
}: {
  visible: boolean
  budget: number | null
  onClose: () => void
  onSave: (budget: number | null) => void
}) {
  const [draft, setDraft] = useState(budget === null ? '' : String(budget))

  return (
    <Modal transparent visible={visible} animationType="fade">
      <View style={styles.overlay}>
        <View style={styles.sheet}>
          <Text style={styles.sheetTitle}>予算（任意）</Text>
          <TextInput
            value={draft}
            onChangeText={setDraft}
            keyboardType="number-pad"
            placeholder="15000"
            placeholderTextColor={colors.muted}
            style={styles.input}
          />
          <Pressable
            style={styles.addBtn}
            onPress={() => {
              const parsed = parseYenInput(draft)
              onSave(parsed)
            }}
          >
            <Text style={styles.addBtnText}>設定</Text>
          </Pressable>
          {budget !== null ? (
            <Pressable onPress={() => onSave(null)}>
              <Text style={styles.manualLink}>予算を解除</Text>
            </Pressable>
          ) : null}
          <Pressable style={styles.outlineBtn} onPress={onClose}>
            <Text style={styles.ink}>閉じる</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  )
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.bg },
  flex: { flex: 1 },
  scroll: { paddingHorizontal: 16, paddingBottom: 24 },
  title: {
    marginTop: 12,
    color: colors.ink,
    fontSize: 26,
    fontWeight: '700',
    textAlign: 'center',
  },
  tagline: { marginTop: 4, color: colors.muted, textAlign: 'center' },
  totalLabel: { marginTop: 16, color: colors.muted, textAlign: 'center' },
  total: {
    marginTop: 4,
    color: colors.gold,
    fontSize: 48,
    fontWeight: '800',
    textAlign: 'center',
  },
  link: { color: colors.muted, textAlign: 'center', textDecorationLine: 'underline', marginTop: 8 },
  budgetBox: {
    marginTop: 12,
    borderWidth: 1,
    borderColor: colors.line,
    backgroundColor: colors.card,
    borderRadius: 16,
    padding: 12,
    alignItems: 'center',
  },
  over: { marginTop: 4, color: colors.danger, fontSize: 20, fontWeight: '700' },
  ok: { marginTop: 4, color: colors.ok, fontSize: 18, fontWeight: '600' },
  rowBetween: { marginTop: 16, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  outlineBtn: {
    borderWidth: 1,
    borderColor: colors.line,
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 10,
    alignItems: 'center',
  },
  ink: { color: colors.ink },
  muted: { color: colors.muted },
  disabled: { opacity: 0.3 },
  empty: { marginTop: 36, color: colors.muted, textAlign: 'center', lineHeight: 22 },
  card: {
    marginTop: 12,
    backgroundColor: colors.card,
    borderColor: colors.line,
    borderWidth: 1,
    borderRadius: 16,
    padding: 16,
  },
  itemName: { color: colors.ink, fontSize: 18, fontWeight: '700', flex: 1, paddingRight: 12 },
  cardBottom: { marginTop: 8 },
  subtotal: { color: colors.gold, fontSize: 24, fontWeight: '700' },
  stepper: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  stepBtn: {
    width: 48,
    height: 48,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: colors.line,
    backgroundColor: colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepText: { color: colors.ink, fontSize: 22 },
  qty: { minWidth: 28, textAlign: 'center', color: colors.ink, fontSize: 20, fontWeight: '600' },
  composer: {
    borderTopWidth: 1,
    borderTopColor: colors.line,
    backgroundColor: colors.bg,
    paddingHorizontal: 12,
    paddingTop: 12,
  },
  inputRow: { flexDirection: 'row', gap: 8 },
  input: {
    height: 56,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.line,
    backgroundColor: colors.card,
    color: colors.ink,
    paddingHorizontal: 16,
    fontSize: 16,
  },
  inputFlex: { flex: 1 },
  error: { marginTop: 8, color: colors.danger },
  addBtn: {
    marginTop: 10,
    height: 56,
    borderRadius: 16,
    backgroundColor: colors.gold,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addBtnText: { color: colors.bg, fontSize: 18, fontWeight: '800' },
  manualLink: {
    marginTop: 10,
    marginBottom: 6,
    color: colors.muted,
    textAlign: 'right',
    textDecorationLine: 'underline',
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    justifyContent: 'flex-end',
    padding: 16,
  },
  sheet: {
    backgroundColor: colors.surface,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: colors.line,
    padding: 20,
    gap: 8,
  },
  sheetTitle: { color: colors.ink, fontSize: 18, fontWeight: '700', textAlign: 'center', marginBottom: 8 },
  label: { color: colors.muted, marginTop: 4 },
  confirm: { paddingBottom: 8 },
  dangerBtn: {
    marginTop: 8,
    height: 56,
    borderRadius: 16,
    backgroundColor: colors.danger,
    alignItems: 'center',
    justifyContent: 'center',
  },
  deleteBtn: {
    marginTop: 16,
    height: 48,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(255,122,112,0.4)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  dangerText: { color: colors.danger },
})
