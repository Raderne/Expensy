import React, { useCallback, useState } from 'react'
import {
  Alert,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { PieChart, Plus } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import {
  useBudgets,
  useBudgetSummary,
  useCreateBudget,
  useUpdateBudget,
  useDeleteBudget,
} from '@/hooks/useBudgets'
import { BudgetCard, BudgetCardSkeleton } from '@/components/budgets/BudgetCard'
import { BudgetFormSheet, type BudgetFormData } from '@/components/budgets/BudgetFormSheet'
import type { BudgetDto, CreateBudgetRequest, UpdateBudgetRequest } from '@/api/types'

// ─── Summary Card ─────────────────────────────────────────────────────────────

interface SummaryCardProps {
  totalBudgeted: number
  totalSpent: number
  percentSpent: number
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount)
}

function SummaryCard({ totalBudgeted, totalSpent, percentSpent }: SummaryCardProps) {
  const remaining = totalBudgeted - totalSpent
  const pct = Math.min(percentSpent, 100)

  const barColor =
    pct >= 100
      ? Colors.danger
      : pct >= 80
        ? Colors.warning
        : Colors.success

  return (
    <View style={summaryStyles.card}>
      <View style={summaryStyles.headerRow}>
        <Text style={summaryStyles.title}>Overall Budget</Text>
        <Text style={[summaryStyles.pctLabel, { color: barColor }]}>
          {pct.toFixed(0)}%
        </Text>
      </View>

      <View style={summaryStyles.statsRow}>
        <View style={summaryStyles.statItem}>
          <Text style={summaryStyles.statLabel}>Budgeted</Text>
          <Text style={summaryStyles.statValue}>{formatCurrency(totalBudgeted)}</Text>
        </View>
        <View style={summaryStyles.statDivider} />
        <View style={summaryStyles.statItem}>
          <Text style={summaryStyles.statLabel}>Spent</Text>
          <Text style={[summaryStyles.statValue, { color: barColor }]}>
            {formatCurrency(totalSpent)}
          </Text>
        </View>
        <View style={summaryStyles.statDivider} />
        <View style={summaryStyles.statItem}>
          <Text style={summaryStyles.statLabel}>Remaining</Text>
          <Text
            style={[
              summaryStyles.statValue,
              { color: remaining < 0 ? Colors.danger : Colors.success },
            ]}
          >
            {formatCurrency(remaining)}
          </Text>
        </View>
      </View>

      <View style={summaryStyles.barTrack}>
        <View
          style={[
            summaryStyles.barFill,
            { width: `${pct}%` as unknown as number, backgroundColor: barColor },
          ]}
        />
      </View>
    </View>
  )
}

const summaryStyles = StyleSheet.create({
  card: {
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: Colors.border.subtle,
    gap: 12,
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  title: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.text.primary,
    letterSpacing: 0.5,
  },
  pctLabel: {
    fontSize: 22,
    fontWeight: '700',
  },
  statsRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
    gap: 2,
  },
  statDivider: {
    width: 1,
    height: 32,
    backgroundColor: Colors.border.subtle,
  },
  statLabel: {
    fontSize: 11,
    color: Colors.text.muted,
    fontWeight: '500',
  },
  statValue: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.text.primary,
  },
  barTrack: {
    height: 4,
    backgroundColor: Colors.bg.overlay,
    borderRadius: 2,
    overflow: 'hidden',
  },
  barFill: {
    height: 4,
    borderRadius: 2,
  },
})

// ─── Empty State ──────────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <View style={styles.emptyContainer}>
      <View style={styles.emptyIconWrap}>
        <PieChart size={40} color={Colors.purple[400]} strokeWidth={1.5} />
      </View>
      <Text style={styles.emptyTitle}>No budgets yet</Text>
      <Text style={styles.emptySubtitle}>
        Create a budget to track your spending limits by category.
      </Text>
    </View>
  )
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function BudgetsScreen() {
  // useBudgets() → thin BudgetDto[] (id, categoryId, limit, period, startDate, endDate)
  // Used for edit pre-fill and delete
  const { data: budgets, isLoading, isError, refetch } = useBudgets()

  // useBudgetSummary() → BudgetProgressDto[] (rich: percentSpent, statusCode, categoryColor…)
  // Used for card display
  const { data: summary } = useBudgetSummary()

  const createBudget = useCreateBudget()
  const updateBudget = useUpdateBudget()
  const deleteBudget = useDeleteBudget()

  const [formVisible, setFormVisible] = useState(false)
  const [editingBudget, setEditingBudget] = useState<BudgetDto | null>(null)
  const [refreshing, setRefreshing] = useState(false)

  const onRefresh = useCallback(async () => {
    setRefreshing(true)
    await refetch()
    setRefreshing(false)
  }, [refetch])

  function openCreate() {
    setEditingBudget(null)
    setFormVisible(true)
  }

  // Called from BudgetCard with the budget id; look up the thin BudgetDto for pre-fill
  function openEdit(id: string) {
    const found = budgets?.find((b) => b.id === id) ?? null
    setEditingBudget(found)
    setFormVisible(true)
  }

  function handleDelete(id: string) {
    Alert.alert(
      'Delete Budget',
      'Are you sure you want to delete this budget? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => deleteBudget.mutate(id),
        },
      ],
    )
  }

  function handleFormSubmit(data: BudgetFormData) {
    if (editingBudget?.id) {
      const req: UpdateBudgetRequest = {
        limit: parseFloat(data.limit),
        period: data.period,
        startDate: new Date(data.startDate),
        endDate: data.endDate ? new Date(data.endDate) : undefined,
      }
      updateBudget.mutate(
        { id: editingBudget.id, req },
        { onSuccess: () => setFormVisible(false) },
      )
    } else {
      const req: CreateBudgetRequest = {
        categoryId: data.categoryId,
        limit: parseFloat(data.limit),
        period: data.period,
        startDate: new Date(data.startDate),
        endDate: data.endDate ? new Date(data.endDate) : undefined,
      }
      createBudget.mutate(req, { onSuccess: () => setFormVisible(false) })
    }
  }

  const isSubmitting = createBudget.isPending || updateBudget.isPending

  // Prefer rich BudgetProgressDto[] from summary for the cards; fall back to empty
  const budgetCards = summary?.budgets ?? []
  const isEmpty = !isLoading && !isError && budgetCards.length === 0
  const overallProgress = summary?.overallProgress

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Budgets</Text>
      </View>

      {/* ── Content ── */}
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={Colors.purple[500]}
            colors={[Colors.purple[500]]}
          />
        }
      >
        {/* Summary card */}
        {overallProgress && !isLoading ? (
          <SummaryCard
            totalBudgeted={overallProgress.totalBudgeted ?? 0}
            totalSpent={overallProgress.totalSpent ?? 0}
            percentSpent={overallProgress.percentSpent ?? 0}
          />
        ) : null}

        {/* Section header */}
        <Text style={styles.sectionHeader}>Active Budgets</Text>

        {/* Budget list */}
        <View style={styles.list}>
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => <BudgetCardSkeleton key={i} />)
          ) : isError ? (
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyTitle}>Something went wrong</Text>
              <Text style={styles.emptySubtitle}>
                Could not load budgets. Pull down to retry.
              </Text>
            </View>
          ) : isEmpty ? (
            <EmptyState />
          ) : (
            budgetCards.map((budget) => (
              <BudgetCard
                key={budget.id}
                budget={budget}
                onEdit={openEdit}
                onDelete={handleDelete}
              />
            ))
          )}
        </View>

        <View style={styles.bottomSpacer} />
      </ScrollView>

      {/* ── FAB ── */}
      <TouchableOpacity
        style={styles.fab}
        onPress={openCreate}
        activeOpacity={0.85}
        accessibilityRole="button"
        accessibilityLabel="Create budget"
      >
        <Plus size={24} color="#FFFFFF" strokeWidth={2.5} />
      </TouchableOpacity>

      {/* ── Form sheet ── */}
      <BudgetFormSheet
        visible={formVisible}
        onClose={() => setFormVisible(false)}
        onSubmit={handleFormSubmit}
        isSubmitting={isSubmitting}
        initial={editingBudget}
      />
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
    color: Colors.text.primary,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingBottom: 24,
    gap: 14,
  },
  sectionHeader: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.text.primary,
    letterSpacing: 0.5,
    marginTop: 4,
  },
  list: {
    gap: 10,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingTop: 48,
    paddingBottom: 24,
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
    color: Colors.text.primary,
    textAlign: 'center',
  },
  emptySubtitle: {
    fontSize: 13,
    color: Colors.text.muted,
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 20,
  },
  bottomSpacer: {
    height: 100,
  },
  fab: {
    position: 'absolute',
    bottom: 80,
    right: 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: Colors.purple[600],
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: Colors.purple[700],
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.5,
    shadowRadius: 8,
    elevation: 8,
  },
})
