import React, { useCallback } from 'react'
import {
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { CreditCard } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import { useSubscriptions, useUpcomingSubscriptions } from '@/hooks/useSubscriptions'
import { SubscriptionCard } from '@/components/subscriptions/SubscriptionCard'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount)
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

// TODO: API — the backend does not yet expose a SubscriptionSummaryDto with
// totalMonthlySpend. Once GET /api/subscriptions/summary is available, replace
// this local computation with the server-side value.
function computeMonthlyTotal(subscriptions: { amount?: number; cycleName?: string; isActive?: boolean }[]): number {
  return subscriptions
    .filter((s) => s.isActive !== false)
    .reduce((sum, s) => {
      const amount = s.amount ?? 0
      const cycle = (s.cycleName ?? '').toLowerCase()
      // Normalise all cycles to a monthly equivalent
      if (cycle === 'daily') return sum + amount * 30
      if (cycle === 'weekly') return sum + amount * 4.33
      if (cycle === 'yearly' || cycle === 'annual') return sum + amount / 12
      return sum + amount // default: monthly
    }, 0)
}

interface SummaryCardProps {
  total: number
  loading: boolean
}

function SummaryCard({ total, loading }: SummaryCardProps) {
  return (
    <View style={styles.summaryCard}>
      <Text style={styles.summaryLabel}>Monthly Total</Text>
      {loading ? (
        <View style={styles.summarySkeletonAmount} />
      ) : (
        <Text style={styles.summaryAmount}>{formatCurrency(total)}</Text>
      )}
      <Text style={styles.summaryNote}>Active subscriptions only</Text>
    </View>
  )
}

// ─── Upcoming Section ─────────────────────────────────────────────────────────

function UpcomingSection() {
  // TODO: API — subscriptionsClient.getUpcoming() when backend adds GET /api/subscriptions/upcoming
  // The useUpcomingSubscriptions hook always returns [] until the endpoint exists.
  const { data: upcoming } = useUpcomingSubscriptions()

  if (!upcoming || upcoming.length === 0) {
    return (
      <View style={styles.upcomingEmpty}>
        <Text style={styles.upcomingEmptyText}>
          No renewals in the next 7 days.
        </Text>
      </View>
    )
  }

  return (
    <View style={styles.cardList}>
      {upcoming.map((s) => (
        <SubscriptionCard key={s.id} subscription={s} />
      ))}
    </View>
  )
}

// ─── Empty State ──────────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <View style={styles.emptyContainer}>
      <View style={styles.emptyIconWrap}>
        <CreditCard size={40} color={Colors.purple[400]} strokeWidth={1.5} />
      </View>
      <Text style={styles.emptyTitle}>No subscriptions yet</Text>
      <Text style={styles.emptySubtitle}>
        Track your recurring subscriptions to keep your spending in check.
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
        Could not load subscriptions. Please try again.
      </Text>
      <TouchableOpacity
        style={styles.retryButton}
        onPress={onRetry}
        activeOpacity={0.75}
        accessibilityRole="button"
        accessibilityLabel="Retry loading subscriptions"
      >
        <Text style={styles.retryText}>Retry</Text>
      </TouchableOpacity>
    </View>
  )
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function SubscriptionsScreen() {
  const { data, isLoading, isError, refetch } = useSubscriptions()

  const onRefresh = useCallback(() => {
    refetch()
  }, [refetch])

  const isEmpty = !isLoading && !isError && (!data || data.length === 0)
  const monthlyTotal = data ? computeMonthlyTotal(data) : 0

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Subscriptions</Text>
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
          {/* Summary card */}
          <View style={styles.paddedSection}>
            <SummaryCard total={monthlyTotal} loading={isLoading} />
          </View>

          {/* Upcoming section */}
          <View style={styles.paddedSection}>
            <Text style={styles.sectionTitle}>Upcoming (7 days)</Text>
            <UpcomingSection />
          </View>

          {/* All subscriptions */}
          {!isEmpty ? (
            <View style={styles.paddedSection}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>All Subscriptions</Text>
                {!isLoading ? (
                  <Text style={styles.sectionCount}>
                    {data?.length ?? 0} total
                  </Text>
                ) : null}
              </View>
              <View style={styles.cardList}>
                {isLoading
                  ? Array.from({ length: 3 }).map((_, i) => (
                      <View key={i} style={styles.skeletonCard} />
                    ))
                  : data?.map((s) => (
                      <SubscriptionCard key={s.id} subscription={s} />
                    ))}
              </View>
            </View>
          ) : !isLoading ? (
            <EmptyState />
          ) : null}

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
    paddingBottom: 12,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    gap: 20,
    paddingBottom: 20,
  },
  paddedSection: {
    paddingHorizontal: 20,
    gap: 10,
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
  // Summary card
  summaryCard: {
    backgroundColor: Colors.purple[700],
    borderRadius: 14,
    paddingHorizontal: 20,
    paddingVertical: 18,
    gap: 4,
  },
  summaryLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.7)',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  summaryAmount: {
    fontSize: 32,
    fontWeight: '700',
    color: '#FFFFFF',
    lineHeight: 40,
  },
  summarySkeletonAmount: {
    height: 36,
    width: '50%',
    borderRadius: 6,
    backgroundColor: 'rgba(255,255,255,0.15)',
    marginVertical: 2,
  },
  summaryNote: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.55)',
    fontWeight: '500',
  },
  // Upcoming empty
  upcomingEmpty: {
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderWidth: 1,
    borderColor: Colors.border.subtle,
    alignItems: 'center',
  },
  upcomingEmptyText: {
    fontSize: 13,
    color: Colors.dark.text.muted,
    fontWeight: '500',
  },
  // Skeleton
  skeletonCard: {
    height: 72,
    borderRadius: 14,
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.subtle,
  },
  // Empty / Error
  emptyContainer: {
    alignItems: 'center',
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
