import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { budgetsClient } from '@/api/clients'
import type {
  BudgetDto,
  BudgetSummaryDto,
  CreateBudgetRequest,
  UpdateBudgetRequest,
} from '@/api/types'

export const BUDGETS_QUERY_KEY = ['budgets'] as const
export const BUDGETS_SUMMARY_QUERY_KEY = ['budgets', 'summary'] as const

export function useBudgets() {
  return useQuery<BudgetDto[], Error>({
    queryKey: BUDGETS_QUERY_KEY,
    queryFn: () => budgetsClient.getAll(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useBudgetSummary() {
  return useQuery<BudgetSummaryDto, Error>({
    queryKey: BUDGETS_SUMMARY_QUERY_KEY,
    queryFn: () => budgetsClient.getSummary(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useCreateBudget() {
  const queryClient = useQueryClient()

  return useMutation<BudgetDto, Error, CreateBudgetRequest>({
    mutationFn: (req) => budgetsClient.create(req),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: BUDGETS_QUERY_KEY })
      queryClient.invalidateQueries({ queryKey: BUDGETS_SUMMARY_QUERY_KEY })
    },
  })
}

export function useUpdateBudget() {
  const queryClient = useQueryClient()

  return useMutation<BudgetDto, Error, { id: string; req: UpdateBudgetRequest }>({
    mutationFn: ({ id, req }) => budgetsClient.update(id, req),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: BUDGETS_QUERY_KEY })
      queryClient.invalidateQueries({ queryKey: BUDGETS_SUMMARY_QUERY_KEY })
    },
  })
}

export function useDeleteBudget() {
  const queryClient = useQueryClient()

  return useMutation<void, Error, string>({
    mutationFn: (id) => budgetsClient.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: BUDGETS_QUERY_KEY })
      queryClient.invalidateQueries({ queryKey: BUDGETS_SUMMARY_QUERY_KEY })
    },
  })
}
