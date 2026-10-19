import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it } from 'vitest'
import { CalendarApp } from './CalendarApp'
import { STORAGE_KEY } from './storage'

describe('カレンダー画面', () => {
  beforeEach(() => {
    localStorage.clear()
    document.title = 'カレンダー'
  })

  it('月・週・日を切り替え、予定を追加・編集・削除して保存する', async () => {
    const user = userEvent.setup()
    const first = render(<CalendarApp />)

    expect(screen.getByRole('heading', { level: 1, name: 'カレンダー' })).toBeTruthy()
    expect(screen.getByText(/「サンプル」の予定は見本です/)).toBeTruthy()
    expect(screen.getAllByText(/サンプル：朝の打ち合わせ/).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/サンプル：歯医者/).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/サンプル：休日/).length).toBeGreaterThan(0)

    await user.click(screen.getByRole('tab', { name: '週表示' }))
    expect(screen.getByRole('button', { name: '前週' })).toBeTruthy()
    await user.click(screen.getByRole('tab', { name: '日表示' }))
    expect(screen.getByRole('button', { name: '前日' })).toBeTruthy()
    await user.click(screen.getByRole('tab', { name: '月表示' }))
    expect(screen.getByRole('tab', { name: '月表示' }).getAttribute('aria-selected')).toBe('true')
    await user.click(screen.getByRole('button', { name: '今日' }))
    await user.click(screen.getByRole('button', { name: '前月' }))
    await user.click(screen.getByRole('button', { name: '次月' }))

    await user.click(screen.getByRole('button', { name: '予定を追加' }))
    const dialog = screen.getByRole('dialog')
    await user.click(within(dialog).getByRole('button', { name: '保存する' }))
    expect(within(dialog).getByRole('alert').textContent).toBe('タイトルを入力してください')
    await user.type(within(dialog).getByLabelText('タイトル'), '企画会議')
    await user.type(within(dialog).getByLabelText('場所（任意）'), '応接室')
    await user.click(within(dialog).getByRole('button', { name: '保存する' }))
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(screen.getAllByText(/企画会議/).length).toBeGreaterThan(0)

    const stored = localStorage.getItem(STORAGE_KEY)
    expect(stored).toBeTruthy()
    expect(stored).toContain('企画会議')

    first.unmount()
    render(<CalendarApp />)
    expect(screen.getAllByText(/企画会議/).length).toBeGreaterThan(0)

    await user.click(screen.getAllByRole('button', { name: /企画会議/ })[0])
    const editor = screen.getByRole('dialog', { name: '予定を編集' })
    const title = within(editor).getByLabelText('タイトル')
    await user.clear(title)
    await user.type(title, '企画の続き')
    await user.click(within(editor).getByRole('button', { name: '保存する' }))
    expect(screen.queryByText(/企画会議/)).toBeNull()
    expect(screen.getAllByText(/企画の続き/).length).toBeGreaterThan(0)

    await user.click(screen.getAllByRole('button', { name: /企画の続き/ })[0])
    const removing = screen.getByRole('dialog')
    await user.click(within(removing).getByRole('button', { name: /^削除$/ }))
    await user.click(within(removing).getByRole('button', { name: '削除する' }))
    expect(screen.queryByText(/企画の続き/)).toBeNull()
    expect(localStorage.getItem(STORAGE_KEY)).not.toContain('企画の続き')

    await user.click(screen.getAllByRole('button', { name: /サンプル：朝の打ち合わせ/ })[0])
    await user.keyboard('{Escape}')
    expect(screen.queryByRole('dialog')).toBeNull()
  })
})
