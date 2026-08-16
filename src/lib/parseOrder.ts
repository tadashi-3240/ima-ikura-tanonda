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

const TRAILING_QTY =
  /(?:(?:×|x|X|✕|＊|\*)\s*([0-9]+|[一二三四五六七八九十]+)|を\s*([0-9]+|[一二三四五六七八九十]+)\s*(?:つ|個|皿|本|杯)?|([0-9]+|[一二三四五六七八九十]+)\s*(?:つ|個|皿|本|杯))\s*$/u

const LEADING_QTY =
  /^(?:(?:×|x|X|✕|＊|\*)\s*([0-9]+|[一二三四五六七八九十]+)|([0-9]+|[一二三四五六七八九十]+)\s*(?:つ|個|皿|本|杯)(?:を)?)\s*/u

export function parseJapaneseNumber(raw: string): number | null {
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

function extractQuantity(segment: string): { quantity: number | null; rest: string } {
  const s = segment.trim()
  if (!s) return { quantity: null, rest: '' }

  const trailing = s.match(TRAILING_QTY)
  if (trailing) {
    const quantity = quantityFromMatch(trailing)
    if (quantity !== null) {
      return { quantity, rest: s.slice(0, trailing.index).trim() }
    }
  }

  const leading = s.match(LEADING_QTY)
  if (leading) {
    const quantity = quantityFromMatch(leading)
    if (quantity !== null) {
      return { quantity, rest: s.slice(leading[0].length).trim() }
    }
  }

  return { quantity: null, rest: s }
}

function cleanName(name: string): string {
  return name
    .replace(/[\s　]*[を、,]+$/u, '')
    .replace(/^[\s　]*[を、,]+/u, '')
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

  const fromAfter = extractQuantity(after)
  const fromBefore =
    fromAfter.quantity === null ? extractQuantity(before) : { quantity: null, rest: before }

  const quantity = fromAfter.quantity ?? fromBefore.quantity ?? 1
  const name = cleanName(fromAfter.quantity !== null ? before : fromBefore.rest)

  return { name, unitPrice, quantity }
}
