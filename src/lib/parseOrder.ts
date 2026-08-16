import type { ParsedOrder } from '../types/order'

const KANJI_DIGIT: Record<string, number> = {
  〇: 0,
  零: 0,
  一: 1,
  二: 2,
  三: 3,
  四: 4,
  五: 5,
  六: 6,
  七: 7,
  八: 8,
  九: 9,
}

const NATIVE_QTY: Record<string, number> = {
  ひとり: 1,
  ひと: 1,
  ふたり: 2,
  ふた: 2,
  みっ: 3,
  よっ: 4,
  いつ: 5,
  むっ: 6,
  なな: 7,
  やっ: 8,
  ここの: 9,
  とお: 10,
}

/** 数字トークン。長い読みを先に置く */
const QTY_NUM =
  '[0-9]+|[一二三四五六七八九十]+|ひとり|ふたり|ここの|ひと|ふた|みっ|よっ|いつ|むっ|なな|やっ|とお'

/** 何個頼むか。1人前を3つ、の「3つ」側 */
const COUNT_UNIT =
  'パック|セット|切れ|枚|串|丁|貫|点|品|合|膳|碗|缶|瓶|食|個|皿|本|杯|つ|さら|ほん|はい|まい|こ'

/** メニューの分量。1人前を3つ、の「1人前」側 */
const SERVING_UNIT = '人前|人盛り|にんまえ|盛り|まえ|前'

const UNIT = `${SERVING_UNIT}|${COUNT_UNIT}`

const QTY_PHRASE = `(?:(?:×|x|X|✕|＊|\\*)\\s*(${QTY_NUM})|を\\s*(${QTY_NUM})\\s*(?:${UNIT})?|(${QTY_NUM})\\s*(?:${UNIT}))`

const COUNT_UNIT_END = new RegExp(`(?:${COUNT_UNIT})$`, 'u')
const SERVING_UNIT_END = new RegExp(`(?:${SERVING_UNIT})$`, 'u')

export function parseJapaneseNumber(raw: string): number | null {
  if (raw in NATIVE_QTY) return NATIVE_QTY[raw]

  if (/^[0-9]+$/.test(raw)) {
    const n = Number.parseInt(raw, 10)
    return Number.isFinite(n) ? n : null
  }

  if (raw === '十') return 10

  const tenToNineteen = raw.match(/^十([一二三四五六七八九])$/)
  if (tenToNineteen) return 10 + KANJI_DIGIT[tenToNineteen[1]]

  const tens = raw.match(/^([一二三四五六七八九])十([一二三四五六七八九])?$/)
  if (tens) {
    return KANJI_DIGIT[tens[1]] * 10 + (tens[2] ? KANJI_DIGIT[tens[2]] : 0)
  }

  if (raw in KANJI_DIGIT) return KANJI_DIGIT[raw]
  return null
}

function quantityFromMatch(match: RegExpMatchArray): number | null {
  const token = match[1] ?? match[2] ?? match[3]
  if (!token) return null
  const n = parseJapaneseNumber(token)
  if (n === null || n <= 0) return null
  return n
}

function classifyQty(raw: string): 'count' | 'serving' | 'bare' {
  const t = raw.trim()
  if (/^[×xX✕＊*]/.test(t)) return 'count'
  const withoutWo = t.replace(/^を\s*/u, '')
  if (COUNT_UNIT_END.test(withoutWo)) return 'count'
  if (SERVING_UNIT_END.test(withoutWo)) return 'serving'
  return 'bare'
}

function extractQuantity(segment: string): { quantity: number | null; rest: string } {
  const s = segment.trim()
  if (!s) return { quantity: null, rest: '' }

  const matches = [...s.matchAll(new RegExp(QTY_PHRASE, 'gu'))]
  const found = []
  for (const match of matches) {
    const quantity = quantityFromMatch(match)
    if (quantity === null) continue
    found.push({ match, quantity, kind: classifyQty(match[0]) })
  }
  if (found.length === 0) return { quantity: null, rest: s }

  const chosen =
    found.filter((item) => item.kind === 'count').at(-1) ??
    found.filter((item) => item.kind === 'bare').at(-1) ??
    found.filter((item) => item.kind === 'serving').at(-1)
  if (!chosen) return { quantity: null, rest: s }

  const start = chosen.match.index ?? 0
  const end = start + chosen.match[0].length
  const rest = `${s.slice(0, start)} ${s.slice(end)}`.replace(/\s+/g, ' ').trim()
  return { quantity: chosen.quantity, rest }
}

function cleanName(name: string): string {
  return name
    .replace(/\s*を\s*/gu, ' ')
    .replace(/[\s　]*[、,]+$/u, '')
    .replace(/^[\s　]*[、,]+/u, '')
    .replace(/[\s　]+/g, ' ')
    .trim()
}

export function parseOrderText(input: string): ParsedOrder | null {
  const text = input.normalize('NFKC').replace(/\s+/g, ' ').trim()
  if (!text) return null

  const priceMatches = [...text.matchAll(/([0-9][0-9,]*)\s*円/g)]
  if (priceMatches.length === 0) return null

  const priceMatch = priceMatches[priceMatches.length - 1]
  const unitPrice = Number.parseInt(priceMatch[1].replace(/,/g, ''), 10)
  if (!Number.isFinite(unitPrice) || unitPrice < 0) return null

  const priceIndex = priceMatch.index ?? 0
  const before = text.slice(0, priceIndex)
  const after = text.slice(priceIndex + priceMatch[0].length)

  const extracted = extractQuantity(`${before} ${after}`.replace(/\s+/g, ' '))
  const quantity = extracted.quantity ?? 1
  const name = cleanName(extracted.rest)

  return { name, unitPrice, quantity }
}
