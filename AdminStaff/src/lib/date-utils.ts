import { format, formatDistanceToNow, parseISO } from 'date-fns'
import { vi } from 'date-fns/locale'

export function formatDate(date: string | Date | null | undefined, formatStr: string = 'dd/MM/yyyy'): string {
  if (!date) return '—'
  const dateObj = typeof date === 'string' ? parseISO(date) : date
  return format(dateObj, formatStr, { locale: vi })
}

export function formatDateTime(date: string | Date | null | undefined): string {
  if (!date) return '—'
  return formatDate(date, 'dd/MM/yyyy HH:mm')
}

export function formatTime(date: string | Date | null | undefined): string {
  if (!date) return '—'
  const dateObj = typeof date === 'string' ? parseISO(date) : date
  return format(dateObj, 'HH:mm', { locale: vi })
}

export function formatRelativeTime(date: string | Date): string {
  const dateObj = typeof date === 'string' ? parseISO(date) : date
  return formatDistanceToNow(dateObj, { addSuffix: true, locale: vi })
}

export function formatRelative(date: string | Date): string {
  return formatRelativeTime(date)
}

export function formatWeekday(date: string | Date): string {
  const dateObj = typeof date === 'string' ? parseISO(date) : date
  return format(dateObj, 'EEEE', { locale: vi })
}
