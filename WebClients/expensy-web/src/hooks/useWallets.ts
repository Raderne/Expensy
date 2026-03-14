import { useQuery } from '@tanstack/react-query'
import { walletsClient } from '@/api/clients'
import type { WalletDto } from '@/api/types'

export const WALLETS_QUERY_KEY = ['wallets'] as const

export function useWallets() {
  return useQuery<WalletDto[], Error>({
    queryKey: WALLETS_QUERY_KEY,
    queryFn: () => walletsClient.getAll(),
    staleTime: 2 * 60 * 1000,   // 2 minutes
    gcTime: 10 * 60 * 1000,     // 10 minutes
    retry: 1,
    refetchOnWindowFocus: false,
  })
}
