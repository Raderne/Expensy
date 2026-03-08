import { apiClient } from './client'

export interface WalletDto {
  id: string
  name: string
  balance: number
  currency: string
  type: string
}

export interface CreateWalletPayload {
  name: string
  balance: number
  currency: string
  type: string
}

export interface UpdateWalletPayload {
  name?: string
  balance?: number
  currency?: string
  type?: string
}

export const walletsApi = {
  getAll: (): Promise<WalletDto[]> =>
    apiClient.get<WalletDto[]>('/wallets').then((r) => r.data),

  create: (payload: CreateWalletPayload): Promise<WalletDto> =>
    apiClient.post<WalletDto>('/wallets', payload).then((r) => r.data),

  update: (id: string, payload: UpdateWalletPayload): Promise<WalletDto> =>
    apiClient.put<WalletDto>(`/wallets/${id}`, payload).then((r) => r.data),

  remove: (id: string): Promise<void> =>
    apiClient.delete(`/wallets/${id}`).then(() => undefined),
}
