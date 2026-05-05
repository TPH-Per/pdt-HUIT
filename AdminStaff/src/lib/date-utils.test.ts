import { describe, it, expect } from 'vitest';
import { formatDateTime, formatDate, formatTime, formatRelative } from './date-utils';

describe('formatDate vi-VN', () => {
  it('formats ISO to dd/MM/yyyy HH:mm', () => {
    expect(formatDateTime('2026-01-15T10:30:00Z')).toMatch(/15\/01\/2026/);
  });

  it('returns — for null', () => {
    expect(formatDate(null)).toBe('—');
  });

  it('returns — for undefined', () => {
    expect(formatDate(undefined)).toBe('—');
  });

  it('formats time correctly', () => {
    expect(formatTime('2026-01-15T10:30:00Z')).toMatch(/10:30/);
  });
});

describe('formatRelative', () => {
  it('returns "Vừa xong" for recent timestamps', () => {
    const now = new Date();
    const recent = new Date(now.getTime() - 30000).toISOString(); // 30 seconds ago
    expect(formatRelative(recent)).toBe('Vừa xong');
  });

  it('returns minutes ago for timestamps under 1 hour', () => {
    const now = new Date();
    const fiveMinutesAgo = new Date(now.getTime() - 5 * 60000).toISOString();
    expect(formatRelative(fiveMinutesAgo)).toBe('5 phút trước');
  });

  it('returns hours ago for timestamps under 1 day', () => {
    const now = new Date();
    const twoHoursAgo = new Date(now.getTime() - 2 * 3600000).toISOString();
    expect(formatRelative(twoHoursAgo)).toBe('2 giờ trước');
  });

  it('returns formatted date for older timestamps', () => {
    const oldDate = '2026-01-15T10:30:00Z';
    expect(formatRelative(oldDate)).toMatch(/15\/01\/2026/);
  });
});
