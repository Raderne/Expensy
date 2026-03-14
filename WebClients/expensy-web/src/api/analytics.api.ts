import { apiClient } from './client'
import { format } from 'date-fns'

// ─── Types ────────────────────────────────────────────────────────────────────

export type AnalyticsPeriod = 'week' | 'month' | 'year'

export interface CategorySpending {
  categoryId: string
  categoryName: string
  categoryIcon: string
  categoryColor: string
  amount: number
  percentage: number
}

export interface SpendingAnalyticsDto {
  periodLabel: string
  totalSpent: number
  previousPeriodTotal: number
  percentageChangeVsPrevious: number | null
  byCategory: CategorySpending[]
}

// ─── API ──────────────────────────────────────────────────────────────────────

export const analyticsApi = {
  getSpending: async (
    period: AnalyticsPeriod,
    referenceDate?: Date,
  ): Promise<SpendingAnalyticsDto> => {
    const dateStr = format(referenceDate ?? new Date(), 'yyyy-MM-dd')
    const { data } = await apiClient.get<SpendingAnalyticsDto>(
      '/analytics/spending',
      { params: { period, referenceDate: dateStr } },
    )
    return data
  },
}
