import { describe, expect, it } from 'vitest'
import { parseOrderText } from './parseOrder'

describe('日本語注文解析', () => {
  it('数量省略時は1になる', () => {
    expect(parseOrderText('刺身980円')).toEqual({
      name: '刺身',
      unitPrice: 980,
      quantity: 1,
    })
    expect(parseOrderText('馬のなめろう850円')).toEqual({
      name: '馬のなめろう',
      unitPrice: 850,
      quantity: 1,
    })
  })

  it('「650円を2つ」を650 + 2と解釈しない', () => {
    const parsed = parseOrderText('650円を2つ')
    expect(parsed).toEqual({
      name: '',
      unitPrice: 650,
      quantity: 2,
    })
    expect(parsed!.unitPrice * parsed!.quantity).toBe(1300)
    expect(parsed!.unitPrice * parsed!.quantity).not.toBe(652)
  })

  it('「650円を2つ」は650 × 2になる', () => {
    const parsed = parseOrderText('ビール650円を2つ')
    expect(parsed).toEqual({
      name: 'ビール',
      unitPrice: 650,
      quantity: 2,
    })
    expect((parsed?.unitPrice ?? 0) * (parsed?.quantity ?? 0)).toBe(1300)
  })

  it('「1100円×2」が正しく解析される', () => {
    expect(parseOrderText('餃子1100円×2')).toEqual({
      name: '餃子',
      unitPrice: 1100,
      quantity: 2,
    })
    expect(parseOrderText('1100円×2')).toEqual({
      name: '',
      unitPrice: 1100,
      quantity: 2,
    })
    expect(parseOrderText('うまうま餃子 1100円を2つ')).toEqual({
      name: 'うまうま餃子',
      unitPrice: 1100,
      quantity: 2,
    })
  })

  it('「600円二つ」が正しく解析される', () => {
    expect(parseOrderText('ご飯600円二つ')).toEqual({
      name: 'ご飯',
      unitPrice: 600,
      quantity: 2,
    })
    expect(parseOrderText('600円二つ')).toEqual({
      name: '',
      unitPrice: 600,
      quantity: 2,
    })
  })

  it('自然文と漢字・記号の数量に対応する', () => {
    expect(parseOrderText('ローストホース1750円を2つ')).toEqual({
      name: 'ローストホース',
      unitPrice: 1750,
      quantity: 2,
    })
    expect(parseOrderText('ご飯600円を2つ')).toEqual({
      name: 'ご飯',
      unitPrice: 600,
      quantity: 2,
    })
    expect(parseOrderText('餃子1100円x2')).toEqual({
      name: '餃子',
      unitPrice: 1100,
      quantity: 2,
    })
    expect(parseOrderText('餃子1100円X2')).toEqual({
      name: '餃子',
      unitPrice: 1100,
      quantity: 2,
    })
    expect(parseOrderText('ビール650円を二個')).toEqual({
      name: 'ビール',
      unitPrice: 650,
      quantity: 2,
    })
    expect(parseOrderText('ビール650円を2個')).toEqual({
      name: 'ビール',
      unitPrice: 650,
      quantity: 2,
    })
    expect(parseOrderText('ビール650円を2皿')).toEqual({
      name: 'ビール',
      unitPrice: 650,
      quantity: 2,
    })
    expect(parseOrderText('ビール650円を2本')).toEqual({
      name: 'ビール',
      unitPrice: 650,
      quantity: 2,
    })
    expect(parseOrderText('ビール650円を2杯')).toEqual({
      name: 'ビール',
      unitPrice: 650,
      quantity: 2,
    })
    expect(parseOrderText('本日の特選牛盛り 4,250円')).toEqual({
      name: '本日の特選牛盛り',
      unitPrice: 4250,
      quantity: 1,
    })
  })

  it('一人前・一皿など飲食店の単位を数量にする', () => {
    expect(parseOrderText('カルビ880円を二人前')).toEqual({
      name: 'カルビ',
      unitPrice: 880,
      quantity: 2,
    })
    expect(parseOrderText('カルビ880円一人前')).toEqual({
      name: 'カルビ',
      unitPrice: 880,
      quantity: 1,
    })
    expect(parseOrderText('カルビ二人前880円')).toEqual({
      name: 'カルビ',
      unitPrice: 880,
      quantity: 2,
    })
    expect(parseOrderText('タン塩980円を一皿')).toEqual({
      name: 'タン塩',
      unitPrice: 980,
      quantity: 1,
    })
    expect(parseOrderText('サラダ480円をひと皿')).toEqual({
      name: 'サラダ',
      unitPrice: 480,
      quantity: 1,
    })
    expect(parseOrderText('冷奴400円を一丁')).toEqual({
      name: '冷奴',
      unitPrice: 400,
      quantity: 1,
    })
    expect(parseOrderText('焼き鳥180円を2串')).toEqual({
      name: '焼き鳥',
      unitPrice: 180,
      quantity: 2,
    })
    expect(parseOrderText('ビール650円をふたつ')).toEqual({
      name: 'ビール',
      unitPrice: 650,
      quantity: 2,
    })
  })

  it('1人前を3つはメニュー分量ではなく個数3にする', () => {
    expect(parseOrderText('カルビ880円 1人前を3つ')).toEqual({
      name: 'カルビ 1人前',
      unitPrice: 880,
      quantity: 3,
    })
    expect(parseOrderText('カルビ1人前を3つ 880円')).toEqual({
      name: 'カルビ1人前',
      unitPrice: 880,
      quantity: 3,
    })
    expect(parseOrderText('カルビ880円を1人前3つ')).toEqual({
      name: 'カルビ 1人前',
      unitPrice: 880,
      quantity: 3,
    })
    expect(parseOrderText('カルビ2人前を3つ 2000円')).toEqual({
      name: 'カルビ2人前',
      unitPrice: 2000,
      quantity: 3,
    })
  })
})
