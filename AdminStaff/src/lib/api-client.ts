import axios, { AxiosError, AxiosInstance, AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import { useAuthStore } from '@/stores/auth'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081/api'

class ApiClient {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
      },
    })

    this.setupInterceptors()
  }

  private setupInterceptors() {
    this.client.interceptors.request.use(
      (config: InternalAxiosRequestConfig) => {
        const authStore = useAuthStore()
        if (authStore.token) {
          config.headers.Authorization = `Bearer ${authStore.token}`
        }
        return config
      },
      (error: AxiosError) => {
        return Promise.reject(error)
      }
    )

    this.client.interceptors.response.use(
      (response: AxiosResponse) => response,
      async (error: AxiosError) => {
        const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

        if (error.response?.status === 401 && !originalRequest._retry) {
          originalRequest._retry = true
          const authStore = useAuthStore()
          
          try {
            await authStore.refreshToken()
            if (authStore.token) {
              originalRequest.headers.Authorization = `Bearer ${authStore.token}`
              return this.client(originalRequest)
            }
          } catch (refreshError) {
            authStore.logout()
            window.location.href = '/login'
            return Promise.reject(refreshError)
          }
        }

        const errorMessage = this.getErrorMessage(error)
        console.error('API Error:', errorMessage)
        
        return Promise.reject({
          message: errorMessage,
          status: error.response?.status,
          data: error.response?.data,
        } as AxiosError)
      }
    )
  }

  private getErrorMessage(error: AxiosError): string {
    if (error.response?.data && typeof error.response.data === 'object') {
      const data = error.response.data as any
      if (data.message) return data.message
      if (data.error) return data.error
    }
    if (error.message) return error.message
    return 'An unexpected error occurred'
  }

  public get<T = any>(url: string, params?: any): Promise<AxiosResponse<T>> {
    return this.client.get<T>(url, { params })
  }

  public post<T = any>(url: string, data?: any): Promise<AxiosResponse<T>> {
    return this.client.post<T>(url, data)
  }

  public put<T = any>(url: string, data?: any): Promise<AxiosResponse<T>> {
    return this.client.put<T>(url, data)
  }

  public patch<T = any>(url: string, data?: any): Promise<AxiosResponse<T>> {
    return this.client.patch<T>(url, data)
  }

  public delete<T = any>(url: string): Promise<AxiosResponse<T>> {
    return this.client.delete<T>(url)
  }
}

export const apiClient = new ApiClient()
export default apiClient
