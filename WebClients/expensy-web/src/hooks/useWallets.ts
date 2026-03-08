import { useQuery } from '@tanstack/react-query'
import { walletsApi, WalletDto } from '@/api/wallets.api'

export const WALLETS_QUERY_KEY = ['wallets'] as const

export function useWallets() {
  return useQuery<WalletDto[], Error>({
    queryKey: WALLETS_QUERY_KEY,
    queryFn: walletsApi.getAll,
    staleTime: 2 * 60 * 1000,   // 2 minutes
    gcTime: 10 * 60 * 1000,     // 10 minutes
    retry: 1,
    refetchOnWindowFocus: false,
  })
}
