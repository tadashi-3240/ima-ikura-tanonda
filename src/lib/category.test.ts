import { describe, expect, it } from 'vitest'
import { classifyOrderCategory, groupByCategory } from './category'

describe('注文の分類', () => {
  it('セット・定食・飲み物・一品を名前から分ける', () => {
    expect(classifyOrderCategory('焼肉セット')).toBe('セット物')
    expect(classifyOrderCategory('日替わり定食')).toBe('定食物')
    expect(classifyOrderCategory('生ビール')).toBe('飲み物')
    expect(classifyOrderCategory('餃子')).toBe('一品料理')
  })

  it('ビールセットはセット物にする', () => {
    expect(classifyOrderCategory('ビールセット')).toBe('セット物')
  })

  it('表示順はセット→定食→一品→飲み物', () => {
    const groups = groupByCategory([
      { name: '生ビール' },
      { name: '餃子' },
      { name: '焼肉セット' },
      { name: '刺身' },
      { name: '日替わり定食' },
      { name: 'ハイボール' },
    ])
    expect(groups.map((group) => group.category)).toEqual([
      'セット物',
      '定食物',
      '一品料理',
      '飲み物',
    ])
    expect(groups[2]?.items.map((item) => item.name)).toEqual(['餃子', '刺身'])
  })
})
