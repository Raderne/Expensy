import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios'
import { router } from 'expo-router'
import { useAuthStore, getStoredRefreshToken, getStoredUserId } from '@/store/auth.store'

// Android emulator maps 10.0.2.2 → host machine localhost.
// For iOS simulator, change this to 'http://localhost:5118/api'.
const BASE_URL = 'http://10.0.2.2:5118/api'

export const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
})

// ---------------------------------------------------------------------------
// Request interceptor — attach Bearer token from in-memory store
// ---------------------------------------------------------------------------
apiClient.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = useAuthStore.getState().accessToken
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// ---------------------------------------------------------------------------
// Response interceptor — silent token refresh on 401
//
// The refresh call is made directly (not through authApi) to avoid a circular
// import: auth.api.ts → client.ts → auth.api.ts.
// ---------------------------------------------------------------------------
let isRefreshing = false
type PendingResolver = (token: string) => void
let pendingQueue: PendingResolver[] = []

function resolvePending(token: string) {
  pendingQueue.forEach((resolve) => resolve(token))
  pendingQueue = []
}

function rejectPending() {
  pendingQueue = []
}

interface RefreshResponse {
  accessToken: string
  refreshToken: string
  userId: string
  email: string
}

apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean }

    if (error.response?.status !== 401 || originalRequest._retry) {
      return Promise.reject(error)
    }

    if (isRefreshing) {
      // Queue this request until the in-flight refresh completes
      return new Promise<string>((resolve) => {
        pendingQueue.push(resolve)
      }).then((newToken) => {
        originalRequest.headers.Authorization = `Bearer ${newToken}`
        return apiClient(originalRequest)
      })
    }

    originalRequest._retry = true
    isRefreshing = true

    try {
      const [refreshToken, userId] = await Promise.all([
        getStoredRefreshToken(),
        getStoredUserId(),
      ])

      if (!refreshToken || !userId) {
        throw new Error('No stored credentials')
      }

      // Direct axios call — bypasses the interceptor on a fresh instance to avoid loops
      const { data } = await axios.post<RefreshResponse>(
        `${BASE_URL}/auth/refresh`,
        { userId, refreshToken },
        { headers: { 'Content-Type': 'application/json' } },
      )

      await useAuthStore.getState().setAuth(
        { id: data.userId, email: data.email },
        data.accessToken,
        data.refreshToken,
      )

      resolvePending(data.accessToken)

      originalRequest.headers.Authorization = `Bearer ${data.accessToken}`
      return apiClient(originalRequest)
    } catch {
      rejectPending()
      await useAuthStore.getState().clearAuth()
      router.replace('/(auth)/login')
      return Promise.reject(error)
    } finally {
      isRefreshing = false
    }
  },
)
