import { useQuery } from '@tanstack/react-query'
import { analyticsClient } from '@/api/clients'
import type { AnalyticsPeriod, SpendingAnalyticsDto } from '@/api/types'

export type { AnalyticsPeriod, SpendingAnalyticsDto }

export const ANALYTICS_QUERY_KEY = (period: AnalyticsPeriod) =>
  ['analytics', 'spending', period] as const

export function useAnalytics(period: AnalyticsPeriod) {
  return useQuery<SpendingAnalyticsDto, Error>({
    queryKey: ANALYTICS_QUERY_KEY(period),
    // referenceDate is omitted — the server uses the current date by default.
    queryFn: () => analyticsClient.getSpending(period, undefined),
    staleTime: 2 * 60 * 1000,   // 2 minutes
    gcTime: 10 * 60 * 1000,     // 10 minutes
    retry: 1,
    refetchOnWindowFocus: false,
  })
}
