import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { settingsClient, subscriptionsClient } from '@/api/clients'
import type {
  CreateSubscriptionRequest,
  SubscriptionCycleDto,
  SubscriptionDto,
  SubscriptionSummaryDto,
  UpdateSubscriptionRequest,
} from '@/api/types'

export const SUBSCRIPTIONS_QUERY_KEY = ['subscriptions'] as const
export const SUBSCRIPTION_CYCLES_QUERY_KEY = ['subscription-cycles'] as const

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

export function useCreateSubscription() {
  const queryClient = useQueryClient()

  return useMutation<SubscriptionDto, Error, CreateSubscriptionRequest>({
    mutationFn: (request) => subscriptionsClient.create(request),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: SUBSCRIPTIONS_QUERY_KEY })
    },
  })
}

export function useUpdateSubscription() {
  const queryClient = useQueryClient()

  return useMutation<SubscriptionDto, Error, { id: string; request: UpdateSubscriptionRequest }>({
    mutationFn: ({ id, request }) => subscriptionsClient.update(id, request),
    onSuccess: (_data, variables) => {
      void queryClient.invalidateQueries({ queryKey: SUBSCRIPTIONS_QUERY_KEY })
      void queryClient.invalidateQueries({
        queryKey: [...SUBSCRIPTIONS_QUERY_KEY, variables.id],
      })
    },
  })
}

export function useDeleteSubscription() {
  const queryClient = useQueryClient()

  return useMutation<void, Error, string>({
    mutationFn: (id) => subscriptionsClient.delete(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: SUBSCRIPTIONS_QUERY_KEY })
    },
  })
}

// Reference data — cycles rarely change, so a 24hr stale time avoids repeated fetches.
export function useSubscriptionCycles() {
  return useQuery<SubscriptionCycleDto[], Error>({
    queryKey: SUBSCRIPTION_CYCLES_QUERY_KEY,
    queryFn: () => settingsClient.getSubscriptionCycles(),
    staleTime: 24 * 60 * 60 * 1000,
    gcTime: 24 * 60 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}
