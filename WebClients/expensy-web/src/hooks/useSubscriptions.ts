import { useQuery } from '@tanstack/react-query'
import { subscriptionsClient } from '@/api/clients'
import type { SubscriptionDto } from '@/api/types'

export const SUBSCRIPTIONS_QUERY_KEY = ['subscriptions'] as const

export function useSubscriptions() {
  return useQuery<SubscriptionDto[], Error>({
    queryKey: SUBSCRIPTIONS_QUERY_KEY,
    queryFn: () => subscriptionsClient.getAll(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

// TODO: API — subscriptionsClient.getUpcoming() when backend adds GET /api/subscriptions/upcoming
// This hook exists as a placeholder so the Subscriptions screen can render an
// "Upcoming" section once the endpoint is available. For now it always returns
// an empty array.
export function useUpcomingSubscriptions() {
  return useQuery<SubscriptionDto[], Error>({
    queryKey: [...SUBSCRIPTIONS_QUERY_KEY, 'upcoming'] as const,
    // TODO: API — replace with subscriptionsClient.getUpcoming() when backend adds GET /api/subscriptions/upcoming
    queryFn: (): Promise<SubscriptionDto[]> => Promise.resolve([]),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}
