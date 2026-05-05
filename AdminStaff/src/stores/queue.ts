import { defineStore } from 'pinia';
import { ref } from 'vue';
import { apiClient } from '@/lib/api-client';

interface QueueStats {
  waiting: number;
  calling: number;
  serving: number;
  completed: number;
}

interface QueueTicket {
  id: number;
  ticketNumber: number;
  ticketPrefix: string;
  studentId: string | null;
  deskId: number;
  status: string;
  createdAt: string;
}

/**
 * Queue Store - Quản lý trạng thái hàng đợi với stale-while-revalidate pattern
 * 
 * Pattern: Cache dữ liệu trong 5 giây, sau đó fetch lại
 * WebSocket invalidates cache khi có cập nhật real-time
 */
export const useQueueStore = defineStore('queue', () => {
  // ==================== STATE ====================
  
  const stats = ref<Record<number, QueueStats>>({});
  const lastFetch = ref<Record<number, number>>({});
  const currentTicket = ref<QueueTicket | null>(null);
  const loading = ref<Record<number, boolean>>({});
  const error = ref<Record<number, string | null>>({});
  
  // Stale-while-revalidate TTL: 5 seconds for real-time queue data
  const STALE_MS = 5000;

  // ==================== ACTIONS ====================

  /**
   * Fetch queue stats with stale-while-revalidate
   * Returns cached data if within TTL, otherwise fetches fresh
   */
  async function fetchStats(deskId: number): Promise<QueueStats | null> {
    const now = Date.now();
    
    // Cache hit - return immediately if within TTL
    if (lastFetch.value[deskId] && now - lastFetch.value[deskId] < STALE_MS) {
      return stats.value[deskId] || null;
    }

    // Cache miss or stale - fetch fresh
    loading.value[deskId] = true;
    error.value[deskId] = null;

    try {
      const response = await apiClient.get(`/registrar/queue/${deskId}/stats`);
      stats.value[deskId] = response.data.data;
      lastFetch.value[deskId] = now;
      return stats.value[deskId];
    } catch (err: any) {
      error.value[deskId] = err.response?.data?.message || 'Failed to fetch queue stats';
      console.error('Queue stats fetch error:', err);
      return null;
    } finally {
      loading.value[deskId] = false;
    }
  }

  /**
   * Invalidate cache for a specific desk
   * Call this when WebSocket push arrives
   */
  function invalidate(deskId: number): void {
    lastFetch.value[deskId] = 0;
  }

  /**
   * Call next ticket
   */
  async function callNext(deskId: number, registrarId: number): Promise<QueueTicket | null> {
    try {
      const response = await apiClient.post(`/registrar/queue/${deskId}/call-next`, {
        registrarId
      });
      currentTicket.value = response.data.data;
      // Invalidate stats after calling
      invalidate(deskId);
      return currentTicket.value;
    } catch (err: any) {
      console.error('Call next error:', err);
      throw new Error(err.response?.data?.message || 'Failed to call next ticket');
    }
  }

  /**
   * Mark ticket as serving
   */
  async function markServing(ticketId: number): Promise<void> {
    try {
      await apiClient.patch(`/registrar/queue/tickets/${ticketId}/serve`);
    } catch (err: any) {
      console.error('Mark serving error:', err);
      throw new Error(err.response?.data?.message || 'Failed to mark as serving');
    }
  }

  /**
   * Mark ticket as completed
   */
  async function markCompleted(ticketId: number): Promise<void> {
    try {
      await apiClient.patch(`/registrar/queue/tickets/${ticketId}/complete`);
    } catch (err: any) {
      console.error('Mark completed error:', err);
      throw new Error(err.response?.data?.message || 'Failed to mark as completed');
    }
  }

  /**
   * Skip ticket
   */
  async function skipTicket(ticketId: number): Promise<void> {
    try {
      await apiClient.patch(`/registrar/queue/tickets/${ticketId}/skip`);
    } catch (err: any) {
      console.error('Skip ticket error:', err);
      throw new Error(err.response?.data?.message || 'Failed to skip ticket');
    }
  }

  // ==================== RETURN ====================
  return {
    // State
    stats,
    currentTicket,
    loading,
    error,
    
    // Actions
    fetchStats,
    invalidate,
    callNext,
    markServing,
    markCompleted,
    skipTicket,
  };
});
