import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { walletsClient } from '@/api/clients'
import type { CreateWalletRequest, WalletDto } from '@/api/types'

export const WALLETS_QUERY_KEY = ['wallets'] as const

export function useWallets() {
  return useQuery<WalletDto[], Error>({
    queryKey: WALLETS_QUERY_KEY,
    queryFn: () => walletsClient.getAll(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useCreateWallet() {
  const queryClient = useQueryClient()
  return useMutation<WalletDto, Error, CreateWalletRequest>({
    mutationFn: (req) => walletsClient.create(req),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: WALLETS_QUERY_KEY })
    },
  })
}

export function useDeleteWallet() {
  const queryClient = useQueryClient()
  return useMutation<void, Error, string>({
    mutationFn: (id) => walletsClient.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: WALLETS_QUERY_KEY })
    },
  })
}
