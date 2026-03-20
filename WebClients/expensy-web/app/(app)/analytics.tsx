import React, { useCallback, useState } from 'react'
import {
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { BarChart2 } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import { useAnalytics } from '@/hooks/useAnalytics'
import type { AnalyticsPeriod } from '@/hooks/useAnalytics'
import { PeriodTabSelector } from '@/components/analytics/PeriodTabSelector'
import { DonutChart } from '@/components/analytics/DonutChart'
import {
  CategoryBreakdownCard,
  CategoryBreakdownCardSkeleton,
} from '@/components/analytics/CategoryBreakdownCard'

// ─── Empty State ──────────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <View style={styles.emptyContainer}>
      <View style={styles.emptyIconWrap}>
        <BarChart2 size={40} color={Colors.purple[400]} strokeWidth={1.5} />
      </View>
      <Text style={styles.emptyTitle}>No spending data</Text>
      <Text style={styles.emptySubtitle}>
        Add some transactions to see your spending breakdown for this period.
      </Text>
    </View>
  )
}

// ─── Error State ──────────────────────────────────────────────────────────────

function ErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <View style={styles.emptyContainer}>
      <Text style={styles.emptyTitle}>Something went wrong</Text>
      <Text style={styles.emptySubtitle}>
        Could not load analytics data. Please try again.
      </Text>
      <TouchableOpacity
        style={styles.retryButton}
        onPress={onRetry}
        activeOpacity={0.75}
        accessibilityRole="button"
        accessibilityLabel="Retry loading analytics"
      >
        <Text style={styles.retryText}>Retry</Text>
      </TouchableOpacity>
    </View>
  )
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function AnalyticsScreen() {
  const [period, setPeriod] = useState<AnalyticsPeriod>('month')

  const { data, isLoading, isError, refetch } = useAnalytics(period)

  const onRefresh = useCallback(() => {
    refetch()
  }, [refetch])

  const onPeriodChange = useCallback((next: AnalyticsPeriod) => {
    setPeriod(next)
  }, [])

  const isEmpty = !isLoading && !isError && (!data || (data.byCategory ?? []).length === 0)

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Spending Analytics</Text>
        {data?.periodLabel ? (
          <Text style={styles.headerSub}>{data.periodLabel}</Text>
        ) : null}
      </View>

      {/* ── Period selector ── */}
      <View style={styles.tabRow}>
        <PeriodTabSelector selected={period} onChange={onPeriodChange} />
      </View>

      {/* ── Content ── */}
      {isError ? (
        <ErrorState onRetry={refetch} />
      ) : (
        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl
              refreshing={isLoading}
              onRefresh={onRefresh}
              tintColor={Colors.purple[500]}
              colors={[Colors.purple[500]]}
            />
          }
        >
          {/* Donut chart */}
          <View style={styles.chartSection}>
            <DonutChart
              totalSpent={data?.totalSpent ?? 0}
              percentageChange={data?.percentageChangeVsPrevious ?? null}
              byCategory={data?.byCategory ?? []}
              loading={isLoading}
            />
          </View>

          {/* Category breakdown */}
          {isEmpty ? (
            <EmptyState />
          ) : (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>Categories</Text>
                <Text style={styles.sectionCount}>
                  {isLoading ? '' : `${(data?.byCategory ?? []).length} total`}
                </Text>
              </View>

              <View style={styles.cardList}>
                {isLoading
                  ? Array.from({ length: 4 }).map((_, i) => (
                      <CategoryBreakdownCardSkeleton key={i} />
                    ))
                  : (data?.byCategory ?? []).map((cat, idx) => (
                      <CategoryBreakdownCard key={cat.categoryId} item={cat} index={idx} />
                    ))}
              </View>
            </View>
          )}

          <View style={styles.bottomSpacer} />
        </ScrollView>
      )}
    </SafeAreaView>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: Colors.bg.base,
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 4,
    gap: 2,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  headerSub: {
    fontSize: 13,
    color: Colors.dark.text.muted,
    fontWeight: '500',
  },
  tabRow: {
    paddingHorizontal: 20,
    paddingVertical: 12,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 20,
  },
  chartSection: {
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 20,
  },
  section: {
    paddingHorizontal: 20,
    gap: 12,
    marginTop: 4,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  sectionCount: {
    fontSize: 12,
    fontWeight: '500',
    color: Colors.dark.text.muted,
  },
  cardList: {
    gap: 10,
  },
  // Empty / Error
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    paddingTop: 48,
    gap: 10,
  },
  emptyIconWrap: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: Colors.bg.elevated,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 4,
  },
  emptyTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.dark.text.primary,
    textAlign: 'center',
  },
  emptySubtitle: {
    fontSize: 13,
    color: Colors.dark.text.muted,
    textAlign: 'center',
    lineHeight: 20,
  },
  retryButton: {
    marginTop: 6,
    paddingHorizontal: 24,
    paddingVertical: 10,
    borderRadius: 10,
    backgroundColor: Colors.purple[600],
  },
  retryText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  bottomSpacer: {
    height: 24,
  },
})
