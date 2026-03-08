import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  transactionsApi,
  TransactionDto,
  PaginatedTransactions,
  TransactionsQuery,
  CreateTransactionPayload,
} from '@/api/transactions.api'

export const TRANSACTIONS_QUERY_KEY = ['transactions'] as const

export function useTransactions(query: TransactionsQuery = {}) {
  return useQuery<PaginatedTransactions, Error>({
    queryKey: [...TRANSACTIONS_QUERY_KEY, query],
    queryFn: () => transactionsApi.getAll(query),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useCreateTransaction() {
  const queryClient = useQueryClient()

  return useMutation<TransactionDto, Error, CreateTransactionPayload>({
    mutationFn: transactionsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: TRANSACTIONS_QUERY_KEY })
      queryClient.invalidateQueries({ queryKey: ['wallets'] })
    },
  })
}
