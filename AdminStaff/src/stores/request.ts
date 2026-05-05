import { defineStore } from 'pinia';
import { ref } from 'vue';
import { apiClient } from '@/lib/api-client';
import type { RequestPhase } from '@/lib/domain';

interface Request {
  id: number;
  studentId: string;
  studentName: string;
  serviceId: number;
  serviceName: string;
  currentPhase: RequestPhase;
  note: string;
  createdAt: string;
  updatedAt: string;
}

interface RequestListResponse {
  content: Request[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

/**
 * Request Store - Quản lý trạng thái yêu cầu với stale-while-revalidate pattern
 * 
 * Pattern: Cache dữ liệu trong 30 giây cho danh sách request
 */
export const useRequestStore = defineStore('request', () => {
  // ==================== STATE ====================
  
  const requests = ref<Request[]>([]);
  const totalElements = ref(0);
  const totalPages = ref(0);
  const currentPage = ref(0);
  const pageSize = ref(10);
  
  const lastFetch = ref<number>(0);
  const loading = ref(false);
  const error = ref<string | null>(null);
  
  // Stale-while-revalidate TTL: 30 seconds for request lists
  const STALE_MS = 30000;

  // ==================== ACTIONS ====================

  /**
   * Fetch requests with stale-while-revalidate
   */
  async function fetchRequests(page: number = 0, size: number = 10, forceRefresh: boolean = false): Promise<void> {
    const now = Date.now();
    
    // Cache hit - return immediately if within TTL and not forcing refresh
    if (!forceRefresh && lastFetch.value && now - lastFetch.value < STALE_MS && currentPage.value === page) {
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const response = await apiClient.get('/registrar/requests', {
        params: { page, size }
      });
      
      const data: RequestListResponse = response.data.data;
      requests.value = data.content;
      totalElements.value = data.totalElements;
      totalPages.value = data.totalPages;
      currentPage.value = data.number;
      pageSize.value = data.size;
      lastFetch.value = now;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to fetch requests';
      console.error('Requests fetch error:', err);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Invalidate cache
   */
  function invalidate(): void {
    lastFetch.value = 0;
  }

  /**
   * Process request (move to next phase)
   */
  async function processRequest(requestId: number): Promise<void> {
    try {
      await apiClient.patch(`/registrar/requests/${requestId}/process`);
      // Invalidate cache after processing
      invalidate();
    } catch (err: any) {
      console.error('Process request error:', err);
      throw new Error(err.response?.data?.message || 'Failed to process request');
    }
  }

  /**
   * Complete request
   */
  async function completeRequest(requestId: number): Promise<void> {
    try {
      await apiClient.patch(`/registrar/requests/${requestId}/complete`);
      // Invalidate cache after completing
      invalidate();
    } catch (err: any) {
      console.error('Complete request error:', err);
      throw new Error(err.response?.data?.message || 'Failed to complete request');
    }
  }

  /**
   * Cancel request
   */
  async function cancelRequest(requestId: number): Promise<void> {
    try {
      await apiClient.patch(`/registrar/requests/${requestId}/cancel`);
      // Invalidate cache after cancelling
      invalidate();
    } catch (err: any) {
      console.error('Cancel request error:', err);
      throw new Error(err.response?.data?.message || 'Failed to cancel request');
    }
  }

  // ==================== RETURN ====================
  return {
    // State
    requests,
    totalElements,
    totalPages,
    currentPage,
    pageSize,
    loading,
    error,
    
    // Actions
    fetchRequests,
    invalidate,
    processRequest,
    completeRequest,
    cancelRequest,
  };
});
