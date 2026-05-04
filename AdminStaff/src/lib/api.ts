/**
 * Axios API Client with Global Error Handling
 */

import axios, { AxiosError, AxiosInstance } from 'axios';
import type { ApiResponse } from './domain';

const api: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor: Add JWT token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('jwt_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// Response interceptor: Handle errors globally
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      // Token expired or invalid
      localStorage.removeItem('jwt_token');
      window.location.href = '/login';
    } else if (error.response?.status === 403) {
      // Forbidden
      console.error('Access denied');
    } else if (error.response?.status === 429) {
      // Rate limited
      console.error('Too many requests. Please try again later.');
    } else if (!error.response) {
      // Network error
      console.error('Network error. Check your connection.');
    }
    return Promise.reject(error);
  },
);

export default api;

/**
 * API Service Methods
 */

export const authApi = {
  login: (username: string, password: string) =>
    api.post<ApiResponse<any>>('/auth/login', { username, password }),

  refresh: (refreshToken: string) =>
    api.post<ApiResponse<any>>('/auth/refresh', { refreshToken }),

  logout: () =>
    api.post<ApiResponse<void>>('/auth/logout'),
};

export const publicApi = {
  getServiceCategories: () =>
    api.get<ApiResponse<any[]>>('/public/service-categories'),
};

export const registrarApi = {
  getDashboard: () =>
    api.get<ApiResponse<any>>('/registrar/dashboard'),

  getQueueStats: (queueId: number) =>
    api.get<ApiResponse<any>>(`/registrar/queue/${queueId}/stats`),

  getQueueNext: (queueId: number) =>
    api.post<ApiResponse<any>>(`/registrar/queue/${queueId}/call-next`),

  serveTicket: (ticketId: number) =>
    api.patch<ApiResponse<any>>(`/registrar/queue/tickets/${ticketId}/serve`),

  completeTicket: (ticketId: number) =>
    api.patch<ApiResponse<any>>(`/registrar/queue/tickets/${ticketId}/complete`),

  getRequests: (page: number = 0, size: number = 20) =>
    api.get<ApiResponse<any>>('/registrar/requests', { params: { page, size } }),

  processRequest: (requestId: number) =>
    api.patch<ApiResponse<any>>(`/registrar/requests/${requestId}/process`),

  completeRequest: (requestId: number) =>
    api.patch<ApiResponse<any>>(`/registrar/requests/${requestId}/complete`),
};
