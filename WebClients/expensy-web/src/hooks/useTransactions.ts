import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { transactionsClient } from '@/api/clients'
import type { TransactionDto, CreateTransactionRequest } from '@/api/types'

export const TRANSACTIONS_QUERY_KEY = ['transactions'] as const

export function useTransactions() {
  return useQuery<TransactionDto[], Error>({
    queryKey: TRANSACTIONS_QUERY_KEY,
    queryFn: () => transactionsClient.getAll(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useCreateTransaction() {
  const queryClient = useQueryClient()

  return useMutation<TransactionDto, Error, CreateTransactionRequest>({
    mutationFn: (req) => transactionsClient.create(req),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: TRANSACTIONS_QUERY_KEY })
      queryClient.invalidateQueries({ queryKey: ['wallets'] })
    },
  })
}
