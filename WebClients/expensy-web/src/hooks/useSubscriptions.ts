import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { subscriptionsClient } from '@/api/clients'
import type { SubscriptionDto, SubscriptionSummaryDto } from '@/api/types'

export const SUBSCRIPTIONS_QUERY_KEY = ['subscriptions'] as const

// getAll now returns SubscriptionSummaryDto — access .subscriptions for the list
// and .totalMonthlySpend for the monthly total card.
export function useSubscriptions() {
  return useQuery<SubscriptionSummaryDto, Error>({
    queryKey: SUBSCRIPTIONS_QUERY_KEY,
    queryFn: () => subscriptionsClient.getAll(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useUpcomingSubscriptions() {
  return useQuery<SubscriptionDto[], Error>({
    queryKey: [...SUBSCRIPTIONS_QUERY_KEY, 'upcoming'] as const,
    queryFn: () => subscriptionsClient.getUpcoming(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useRemindSubscription() {
  const queryClient = useQueryClient()

  return useMutation<void, Error, string>({
    mutationFn: (id: string) => subscriptionsClient.remind(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: SUBSCRIPTIONS_QUERY_KEY })
    },
  })
}
