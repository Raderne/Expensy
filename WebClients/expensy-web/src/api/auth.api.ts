import { apiClient } from './client'

export interface AuthResponse {
  accessToken: string
  refreshToken: string
  userId: string
  email: string
}

export interface RegisterPayload {
  email: string
  password: string
  userName: string
}

export interface LoginPayload {
  email: string
  password: string
}

export interface RefreshPayload {
  userId: string
  refreshToken: string
}

export const authApi = {
  register: (payload: RegisterPayload): Promise<AuthResponse> =>
    apiClient.post<AuthResponse>('/auth/register', payload).then((r) => r.data),

  login: (payload: LoginPayload): Promise<AuthResponse> =>
    apiClient.post<AuthResponse>('/auth/login', payload).then((r) => r.data),

  refresh: (payload: RefreshPayload): Promise<AuthResponse> =>
    apiClient.post<AuthResponse>('/auth/refresh', payload).then((r) => r.data),

  // Requires Bearer token; body is the raw refresh token string
  revoke: (refreshToken: string): Promise<void> =>
    apiClient.post('/auth/revoke', refreshToken, {
      headers: { 'Content-Type': 'application/json' },
    }).then(() => undefined),
}
