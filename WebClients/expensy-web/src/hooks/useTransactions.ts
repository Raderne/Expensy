import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { transactionsClient } from '@/api/clients'
import type {
  TransactionDto,
  CreateTransactionRequest,
  UpdateTransactionRequest,
} from '@/api/types'

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

export function useUpdateTransaction() {
  const queryClient = useQueryClient()

  return useMutation<TransactionDto, Error, { id: string; req: UpdateTransactionRequest }>({
    mutationFn: ({ id, req }) => transactionsClient.update(id, req),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: TRANSACTIONS_QUERY_KEY })
      queryClient.invalidateQueries({ queryKey: ['wallets'] })
    },
  })
}

export function useDeleteTransaction() {
  const queryClient = useQueryClient()

  return useMutation<void, Error, string>({
    mutationFn: (id) => transactionsClient.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: TRANSACTIONS_QUERY_KEY })
      queryClient.invalidateQueries({ queryKey: ['wallets'] })
    },
  })
}
