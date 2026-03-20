import { useQuery } from '@tanstack/react-query'
import { savingsGoalsClient } from '@/api/clients'
import type { SavingsGoalDto } from '@/api/types'

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
