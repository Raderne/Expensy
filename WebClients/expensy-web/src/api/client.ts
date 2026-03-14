import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';
import { router } from 'expo-router';
import { useAuthStore, getStoredRefreshToken, getStoredUserId } from '@/store/auth.store';
import type { AuthResponse } from './generated/api-client';

// Android emulator maps 10.0.2.2 → host machine localhost.
// For iOS simulator or physical device, change to the machine's LAN IP.
export const BASE_URL = 'http://192.168.1.12:5118';

// ---------------------------------------------------------------------------
// nswagAxios — shared axios instance for all NSwag-generated clients.
//
// IMPORTANT: `transformResponse: [(data) => data]` disables axios's automatic
// JSON parsing. NSwag-generated process* methods call JSON.parse(response.data)
// themselves; if axios has already parsed the body, response.data is an object
// and JSON.parse(object) throws a SyntaxError ("Unexpected token o in JSON").
// Passing the raw string through lets NSwag's own parse succeed.
// ---------------------------------------------------------------------------
export const nswagAxios = axios.create({
  headers: { 'Content-Type': 'application/json' },
  transformResponse: [(data) => data],
});

// ---------------------------------------------------------------------------
// Request interceptor — attach Bearer token from in-memory store
// ---------------------------------------------------------------------------
nswagAxios.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = useAuthStore.getState().accessToken;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// ---------------------------------------------------------------------------
// Response interceptor — silent token refresh on 401
//
// The refresh call is made directly (not through authClient) to avoid a
// circular import: clients.ts → client.ts → clients.ts.
// ---------------------------------------------------------------------------
let isRefreshing = false;
type PendingResolver = (token: string) => void;
let pendingQueue: PendingResolver[] = [];

function resolvePending(token: string) {
  pendingQueue.forEach((resolve) => resolve(token));
  pendingQueue = [];
}

function rejectPending() {
  pendingQueue = [];
}

nswagAxios.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };

    if (error.response?.status !== 401 || originalRequest._retry) {
      return Promise.reject(error);
    }

    if (isRefreshing) {
      // Queue this request until the in-flight refresh completes
      return new Promise<string>((resolve) => {
        pendingQueue.push(resolve);
      }).then((newToken) => {
        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        return nswagAxios(originalRequest);
      });
    }

    originalRequest._retry = true;
    isRefreshing = true;

    try {
      const [refreshToken, userId] = await Promise.all([getStoredRefreshToken(), getStoredUserId()]);

      if (!refreshToken || !userId) {
        throw new Error('No stored credentials');
      }

      // Direct axios call on a fresh instance — bypasses nswagAxios interceptors to
      // avoid infinite retry loops, and avoids the double-parse issue by using a
      // plain instance (refresh response is parsed manually below).
      const { data: rawData } = await axios.post<string>(
        `${BASE_URL}/api/Auth/refresh`,
        { userId, refreshToken },
        { headers: { 'Content-Type': 'application/json' } },
      );

      const data: AuthResponse = typeof rawData === 'string' ? JSON.parse(rawData) : rawData;

      // AuthResponse fields are optional in the generated type; guard before use.
      if (!data.accessToken || !data.refreshToken || !data.userId || !data.email) {
        throw new Error('Malformed refresh response');
      }

      await useAuthStore.getState().setAuth({ id: data.userId, email: data.email }, data.accessToken, data.refreshToken);

      resolvePending(data.accessToken);

      originalRequest.headers.Authorization = `Bearer ${data.accessToken}`;
      return nswagAxios(originalRequest);
    } catch {
      rejectPending();
      await useAuthStore.getState().clearAuth();
      router.replace('/(auth)/login');
      return Promise.reject(error);
    } finally {
      isRefreshing = false;
    }
  },
);

// ---------------------------------------------------------------------------
// apiClient — kept as a convenience alias for any direct axios calls that do
// not go through an NSwag client. Uses nswagAxios so auth interceptors apply.
// ---------------------------------------------------------------------------
export const apiClient = nswagAxios;
