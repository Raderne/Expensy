import { WALLETS_API } from '@/api/clients'
import type { WalletDto, CreateWalletRequest, UpdateWalletRequest } from '@/api/types'

export type { WalletDto, CreateWalletRequest, UpdateWalletRequest }

export const walletsApi = {
  getAll: (): Promise<WalletDto[]> => WALLETS_API.getAll(),
  create: (req: CreateWalletRequest): Promise<WalletDto> => WALLETS_API.create(req),
  update: (id: string, req: UpdateWalletRequest): Promise<WalletDto> => WALLETS_API.update(id, req),
  remove: (id: string): Promise<void> => WALLETS_API.delete(id),
}
