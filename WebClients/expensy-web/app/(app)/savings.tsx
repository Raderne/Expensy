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
import { PiggyBank, Plus } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import { useSavingsGoals } from '@/hooks/useSavingsGoals'
import { GoalCard, GoalCardSkeleton } from '@/components/savings/GoalCard'

// ─── Empty State ──────────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <View style={styles.emptyContainer}>
      <View style={styles.emptyIconWrap}>
        <PiggyBank size={40} color={Colors.purple[400]} strokeWidth={1.5} />
      </View>
      <Text style={styles.emptyTitle}>No savings goals yet</Text>
      <Text style={styles.emptySubtitle}>
        Create a savings goal to start tracking your progress toward something meaningful.
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
        Could not load your savings goals. Please try again.
      </Text>
      <TouchableOpacity
        style={styles.retryButton}
        onPress={onRetry}
        activeOpacity={0.75}
        accessibilityRole="button"
        accessibilityLabel="Retry loading savings goals"
      >
        <Text style={styles.retryText}>Retry</Text>
      </TouchableOpacity>
    </View>
  )
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function SavingsScreen() {
  const { data, isLoading, isError, refetch } = useSavingsGoals()

  const onRefresh = useCallback(() => {
    refetch()
  }, [refetch])

  const isEmpty = !isLoading && !isError && (!data || data.length === 0)

  function handleAddGoal() {
    // TODO: API — navigate to create savings goal screen when form is implemented
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Savings Goals</Text>
        <TouchableOpacity
          style={styles.addButton}
          onPress={handleAddGoal}
          activeOpacity={0.75}
          accessibilityRole="button"
          accessibilityLabel="Add savings goal"
        >
          <Plus size={20} color={Colors.dark.text.primary} strokeWidth={2} />
        </TouchableOpacity>
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
          <View style={styles.section}>
            {isLoading ? (
              Array.from({ length: 3 }).map((_, i) => <GoalCardSkeleton key={i} />)
            ) : isEmpty ? (
              <EmptyState />
            ) : (
              data?.map((goal, idx) => (
                <GoalCard key={goal.id} goal={goal} index={idx} />
              ))
            )}
          </View>

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
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 12,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  addButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.bg.elevated,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.dark.border.subtle,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 20,
  },
  section: {
    paddingHorizontal: 20,
    gap: 10,
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    paddingTop: 80,
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
