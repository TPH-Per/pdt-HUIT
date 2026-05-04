import { describe, expect, it } from 'vitest'
import { cn } from './utils'

describe('cn', () => {
  it('merges plain class names', () => {
    expect(cn('px-4', 'py-2')).toBe('px-4 py-2')
  })

  it('merges tailwind conflicts by keeping the latest class', () => {
    expect(cn('px-2', 'px-4')).toBe('px-4')
  })

  it('handles conditional values via clsx semantics', () => {
    expect(cn('text-sm', false && 'hidden', null, undefined, 'font-medium')).toBe(
      'text-sm font-medium',
    )
  })
})
