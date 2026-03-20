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
import {
  useSubscriptions,
  useUpcomingSubscriptions,
  useRemindSubscription,
} from '@/hooks/useSubscriptions'
import { SubscriptionCard } from '@/components/subscriptions/SubscriptionCard'
import type { SubscriptionDto } from '@/api/types'

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

interface UpcomingItemProps {
  subscription: SubscriptionDto
  onRemind: (id: string) => void
  isReminding: boolean
}

function UpcomingItem({ subscription, onRemind, isReminding }: UpcomingItemProps) {
  function handleRemind() {
    if (subscription.id) {
      onRemind(subscription.id)
    }
  }

  return (
    <View style={styles.upcomingItem}>
      <View style={styles.upcomingItemLeft}>
        <SubscriptionCard subscription={subscription} />
      </View>
      <TouchableOpacity
        style={[styles.remindButton, isReminding && styles.remindButtonDisabled]}
        onPress={handleRemind}
        disabled={isReminding}
        activeOpacity={0.75}
        accessibilityRole="button"
        accessibilityLabel={`Remind me about ${subscription.name ?? 'subscription'}`}
      >
        <Text style={styles.remindButtonText}>Remind</Text>
      </TouchableOpacity>
    </View>
  )
}

function UpcomingSection() {
  const { data: upcoming } = useUpcomingSubscriptions()
  const { mutate: remind, isPending: isReminding } = useRemindSubscription()

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
        <UpcomingItem
          key={s.id}
          subscription={s}
          onRemind={remind}
          isReminding={isReminding}
        />
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

  const subscriptions = data?.subscriptions ?? []
  const monthlyTotal = data?.totalMonthlySpend ?? 0
  const isEmpty = !isLoading && !isError && subscriptions.length === 0

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
                    {subscriptions.length} total
                  </Text>
                ) : null}
              </View>
              <View style={styles.cardList}>
                {isLoading
                  ? Array.from({ length: 3 }).map((_, i) => (
                      <View key={i} style={styles.skeletonCard} />
                    ))
                  : subscriptions.map((s) => (
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
  // Upcoming item with remind button
  upcomingItem: {
    gap: 8,
  },
  upcomingItemLeft: {
    flex: 1,
  },
  remindButton: {
    alignSelf: 'flex-end',
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: Colors.purple[600],
  },
  remindButtonDisabled: {
    opacity: 0.5,
  },
  remindButtonText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#FFFFFF',
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
