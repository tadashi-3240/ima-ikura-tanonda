export const ORDER_CATEGORIES = ['セット物', '定食物', '一品料理', '飲み物'] as const

export type OrderCategory = (typeof ORDER_CATEGORIES)[number]

const DRINK_WORDS = [
  'ビール',
  '生ビール',
  'ハイボール',
  'チューハイ',
  '酎ハイ',
  'サワー',
  '日本酒',
  '焼酎',
  'ワイン',
  'シャンパン',
  'カクテル',
  'ウーロン',
  '緑茶',
  '麦茶',
  '紅茶',
  'お茶',
  'コーヒー',
  'コーラ',
  'ジュース',
  'サイダー',
  'ソーダ',
  'ミネラルウォーター',
  '炭酸水',
  'ドリンク',
  'ノンアル',
  'ソフトドリンク',
  '生中',
  '生大',
  '生小',
  '瓶ビール',
  '梅酒',
  '果実酒',
  'レモンサワー',
  'グレープフルーツサワー',
  '角ハイ',
]

/** 飲み物判定より先に見る（ビールセットなど） */
function isSet(name: string): boolean {
  return /セット|set/i.test(name)
}

function isTeishoku(name: string): boolean {
  return /定食|膳/.test(name)
}

function isDrink(name: string): boolean {
  return DRINK_WORDS.some((word) => name.includes(word))
}

export function classifyOrderCategory(name: string): OrderCategory {
  const trimmed = name.trim()
  if (isSet(trimmed)) return 'セット物'
  if (isTeishoku(trimmed)) return '定食物'
  if (isDrink(trimmed)) return '飲み物'
  return '一品料理'
}

export function groupByCategory<T extends { name: string }>(
  items: T[],
): { category: OrderCategory; items: T[] }[] {
  const buckets = new Map<OrderCategory, T[]>(
    ORDER_CATEGORIES.map((category) => [category, []]),
  )
  for (const item of items) {
    buckets.get(classifyOrderCategory(item.name))!.push(item)
  }
  return ORDER_CATEGORIES.map((category) => ({
    category,
    items: buckets.get(category)!,
  })).filter((group) => group.items.length > 0)
}
