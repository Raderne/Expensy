import { AUTH_API } from '@/api/clients'
import type { AuthResponse, LoginRequest, RegisterRequest, RefreshRequest } from '@/api/types'

export type { AuthResponse, LoginRequest, RegisterRequest, RefreshRequest }

export const authApi = {
  login: (req: LoginRequest): Promise<AuthResponse> => AUTH_API.login(req),
  register: (req: RegisterRequest): Promise<AuthResponse> => AUTH_API.register(req),
  refresh: (req: RefreshRequest): Promise<AuthResponse> => AUTH_API.refresh(req),
  revoke: (token: string): Promise<void> => AUTH_API.revoke(token),
}
