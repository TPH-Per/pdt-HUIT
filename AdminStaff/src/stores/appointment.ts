import { defineStore } from 'pinia';
import { ref } from 'vue';
import { apiClient } from '@/lib/api-client';

interface Appointment {
  id: number;
  requestId: number;
  registrarId: number;
  appointmentDate: string;
  appointmentTime: string;
  status: number; // 0: BOOKED, 1: COMPLETED, 2: CANCELLED
  notes: string | null;
}

interface AvailableSlot {
  time: string;
  available: boolean;
}

/**
 * Appointment Store - Quản lý trạng thái lịch hẹn với stale-while-revalidate pattern
 * 
 * Pattern: Cache dữ liệu trong 15 phút cho available slots
 */
export const useAppointmentStore = defineStore('appointment', () => {
  // ==================== STATE ====================
  
  const appointments = ref<Appointment[]>([]);
  const availableSlots = ref<AvailableSlot[]>([]);
  const lastFetchSlots = ref<Record<string, number>>({});
  
  const loading = ref(false);
  const error = ref<string | null>(null);
  
  // Stale-while-revalidate TTL: 15 minutes for available slots
  const STALE_MS = 15 * 60 * 1000;

  // ==================== ACTIONS ====================

  /**
   * Fetch available slots with stale-while-revalidate
   */
  async function fetchAvailableSlots(serviceId: number, date: string, forceRefresh: boolean = false): Promise<void> {
    const cacheKey = `${serviceId}-${date}`;
    const now = Date.now();
    
    // Cache hit - return immediately if within TTL and not forcing refresh
    if (!forceRefresh && lastFetchSlots.value[cacheKey] && now - lastFetchSlots.value[cacheKey] < STALE_MS) {
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const response = await apiClient.get('/registrar/appointments/available-slots', {
        params: { serviceId, date }
      });
      
      availableSlots.value = response.data.data;
      lastFetchSlots.value[cacheKey] = now;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to fetch available slots';
      console.error('Available slots fetch error:', err);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Invalidate cache for available slots
   */
  function invalidateSlots(serviceId: number, date: string): void {
    const cacheKey = `${serviceId}-${date}`;
    lastFetchSlots.value[cacheKey] = 0;
  }

  /**
   * Fetch appointments for a registrar
   */
  async function fetchAppointments(registrarId: number, date: string): Promise<void> {
    loading.value = true;
    error.value = null;

    try {
      const response = await apiClient.get('/registrar/appointments', {
        params: { registrarId, date }
      });
      
      appointments.value = response.data.data;
    } catch (err: any) {
      error.value = err.response?.data?.message || 'Failed to fetch appointments';
      console.error('Appointments fetch error:', err);
    } finally {
      loading.value = false;
    }
  }

  /**
   * Create appointment
   */
  async function createAppointment(data: {
    requestId: number;
    registrarId: number;
    appointmentDate: string;
    appointmentTime: string;
    notes?: string;
  }): Promise<Appointment> {
    try {
      const response = await apiClient.post('/registrar/appointments', data);
      // Invalidate slots cache after creating
      invalidateSlots(data.registrarId, data.appointmentDate);
      return response.data.data;
    } catch (err: any) {
      console.error('Create appointment error:', err);
      throw new Error(err.response?.data?.message || 'Failed to create appointment');
    }
  }

  /**
   * Cancel appointment
   */
  async function cancelAppointment(appointmentId: number, registrarId: number, date: string): Promise<void> {
    try {
      await apiClient.patch(`/registrar/appointments/${appointmentId}/cancel`);
      // Invalidate slots cache after cancelling
      invalidateSlots(registrarId, date);
    } catch (err: any) {
      console.error('Cancel appointment error:', err);
      throw new Error(err.response?.data?.message || 'Failed to cancel appointment');
    }
  }

  /**
   * Complete appointment
   */
  async function completeAppointment(appointmentId: number): Promise<void> {
    try {
      await apiClient.patch(`/registrar/appointments/${appointmentId}/complete`);
    } catch (err: any) {
      console.error('Complete appointment error:', err);
      throw new Error(err.response?.data?.message || 'Failed to complete appointment');
    }
  }

  // ==================== RETURN ====================
  return {
    // State
    appointments,
    availableSlots,
    loading,
    error,
    
    // Actions
    fetchAvailableSlots,
    invalidateSlots,
    fetchAppointments,
    createAppointment,
    cancelAppointment,
    completeAppointment,
  };
});
