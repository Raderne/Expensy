import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { savingsGoalsClient } from '@/api/clients'
import type {
  SavingsGoalDto,
  CreateSavingsGoalRequest,
  UpdateSavingsGoalRequest,
  AddFundsRequest,
} from '@/api/types'

export const SAVINGS_GOALS_QUERY_KEY = ['savings-goals'] as const

export function useSavingsGoals() {
  return useQuery<SavingsGoalDto[], Error>({
    queryKey: SAVINGS_GOALS_QUERY_KEY,
    queryFn: () => savingsGoalsClient.getAll(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useCreateSavingsGoal() {
  const queryClient = useQueryClient()

  return useMutation<SavingsGoalDto, Error, CreateSavingsGoalRequest>({
    mutationFn: (req) => savingsGoalsClient.create(req),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: SAVINGS_GOALS_QUERY_KEY })
    },
  })
}

export function useUpdateSavingsGoal() {
  const queryClient = useQueryClient()

  return useMutation<SavingsGoalDto, Error, { id: string; req: UpdateSavingsGoalRequest }>({
    mutationFn: ({ id, req }) => savingsGoalsClient.update(id, req),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: SAVINGS_GOALS_QUERY_KEY })
    },
  })
}

export function useDeleteSavingsGoal() {
  const queryClient = useQueryClient()

  return useMutation<void, Error, string>({
    mutationFn: (id) => savingsGoalsClient.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: SAVINGS_GOALS_QUERY_KEY })
    },
  })
}

export function useAddFunds() {
  const queryClient = useQueryClient()

  return useMutation<SavingsGoalDto, Error, { id: string; req: AddFundsRequest }>({
    mutationFn: ({ id, req }) => savingsGoalsClient.addFunds(id, req),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: SAVINGS_GOALS_QUERY_KEY })
    },
  })
}
