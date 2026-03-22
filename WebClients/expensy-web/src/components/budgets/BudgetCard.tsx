import React, { useEffect, useRef } from 'react'
import {
  Animated,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { Trash2, Pencil } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import type { BudgetProgressDto } from '@/api/types'

// ─── Types ────────────────────────────────────────────────────────────────────

interface BudgetCardProps {
  budget: BudgetProgressDto
  onEdit?: (id: string) => void
  onDelete?: (id: string) => void
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount)
}

/**
 * statusCode → progress bar / badge color
 *   OnTrack (0)    → success (green)
 *   Good (1)       → purple
 *   NearLimit (2)  → warning (orange)
 *   OverBudget (3) → danger (red)
 */
function getStatusColor(statusCode: number | undefined): string {
  switch (statusCode) {
    case 0:
      return Colors.success
    case 1:
      return Colors.purple[500]
    case 2:
      return Colors.warning
    case 3:
      return Colors.danger
    default:
      return Colors.purple[500]
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

export function BudgetCardSkeleton() {
  const pulse = useRef(new Animated.Value(0.4)).current

  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 1, duration: 900, useNativeDriver: true }),
        Animated.timing(pulse, { toValue: 0.4, duration: 900, useNativeDriver: true }),
      ]),
    ).start()
  }, [pulse])

  return (
    <Animated.View style={[styles.card, { opacity: pulse }]}>
      <View style={styles.topRow}>
        <View style={styles.skeletonIcon} />
        <View style={styles.skeletonCenter}>
          <View style={styles.skeletonTitle} />
          <View style={styles.skeletonSubtitle} />
        </View>
        <View style={styles.skeletonAmounts} />
      </View>
      <View style={styles.barTrack} />
    </Animated.View>
  )
}

// ─── Component ────────────────────────────────────────────────────────────────

export function BudgetCard({ budget, onEdit, onDelete }: BudgetCardProps) {
  const barWidth = useRef(new Animated.Value(0)).current

  const percent = Math.min(budget.percentSpent ?? 0, 100)
  const statusColor = getStatusColor(budget.statusCode)
  const iconBg = budget.categoryColor
    ? `${budget.categoryColor}22`
    : `${Colors.purple[500]}22`
  const iconColor = budget.categoryColor ?? Colors.purple[500]

  useEffect(() => {
    barWidth.setValue(0)
    Animated.timing(barWidth, {
      toValue: percent,
      duration: 700,
      useNativeDriver: false, // width % cannot use native driver
    }).start()
  }, [percent, barWidth])

  const animatedBarWidth = barWidth.interpolate({
    inputRange: [0, 100],
    outputRange: ['0%', '100%'],
  })

  return (
    <View style={styles.card}>
      {/* ── Top row ── */}
      <View style={styles.topRow}>
        {/* Icon circle */}
        <View style={[styles.iconCircle, { backgroundColor: iconBg }]}>
          <Text style={styles.iconText}>
            {budget.categoryIcon ?? budget.categoryName?.charAt(0).toUpperCase() ?? '?'}
          </Text>
        </View>

        {/* Center: name + insight */}
        <View style={styles.centerGroup}>
          <Text style={styles.categoryName} numberOfLines={1}>
            {budget.categoryName ?? 'Uncategorized'}
          </Text>
          {budget.insightTip ? (
            <Text style={styles.insightText} numberOfLines={1}>
              {budget.insightTip}
            </Text>
          ) : null}
        </View>

        {/* Right: spent / limit */}
        <View style={styles.amountGroup}>
          <Text style={styles.spentAmount}>{formatCurrency(budget.spent ?? 0)}</Text>
          <Text style={styles.limitAmount}>of {formatCurrency(budget.limit ?? 0)}</Text>
        </View>
      </View>

      {/* ── Progress bar ── */}
      <View style={styles.barTrack}>
        <Animated.View
          style={[styles.bar, { width: animatedBarWidth, backgroundColor: statusColor }]}
        />
      </View>

      {/* ── Bottom row: status badge + actions ── */}
      <View style={styles.bottomRow}>
        {budget.statusTitle ? (
          <View style={[styles.statusBadge, { backgroundColor: `${statusColor}20` }]}>
            <Text style={[styles.statusBadgeText, { color: statusColor }]}>
              {budget.statusTitle}
            </Text>
          </View>
        ) : (
          <View />
        )}

        <View style={styles.actions}>
          {onEdit && budget.id ? (
            <TouchableOpacity
              style={styles.actionBtn}
              onPress={() => onEdit(budget.id!)}
              activeOpacity={0.7}
              accessibilityRole="button"
              accessibilityLabel={`Edit ${budget.categoryName} budget`}
            >
              <Pencil size={14} color={Colors.text.secondary} strokeWidth={2} />
            </TouchableOpacity>
          ) : null}
          {onDelete && budget.id ? (
            <TouchableOpacity
              style={styles.actionBtn}
              onPress={() => onDelete(budget.id!)}
              activeOpacity={0.7}
              accessibilityRole="button"
              accessibilityLabel={`Delete ${budget.categoryName} budget`}
            >
              <Trash2 size={14} color={Colors.danger} strokeWidth={2} />
            </TouchableOpacity>
          ) : null}
        </View>
      </View>
    </View>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingTop: 14,
    paddingBottom: 12,
    borderWidth: 1,
    borderColor: Colors.border.subtle,
    gap: 10,
  },
  topRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  iconCircle: {
    width: 42,
    height: 42,
    borderRadius: 21,
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  iconText: {
    fontSize: 19,
  },
  centerGroup: {
    flex: 1,
    gap: 2,
  },
  categoryName: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.text.primary,
  },
  insightText: {
    fontSize: 11,
    color: Colors.text.muted,
    fontWeight: '500',
  },
  amountGroup: {
    alignItems: 'flex-end',
    gap: 1,
    flexShrink: 0,
  },
  spentAmount: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.text.primary,
  },
  limitAmount: {
    fontSize: 11,
    color: Colors.text.muted,
    fontWeight: '500',
  },
  barTrack: {
    height: 4,
    backgroundColor: Colors.bg.overlay,
    borderRadius: 2,
    overflow: 'hidden',
  },
  bar: {
    height: 4,
    borderRadius: 2,
  },
  bottomRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  statusBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  actions: {
    flexDirection: 'row',
    gap: 4,
  },
  actionBtn: {
    width: 28,
    height: 28,
    borderRadius: 8,
    backgroundColor: Colors.bg.overlay,
    alignItems: 'center',
    justifyContent: 'center',
  },
  // Skeleton
  skeletonIcon: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonCenter: {
    flex: 1,
    gap: 6,
  },
  skeletonTitle: {
    height: 13,
    width: '55%',
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonSubtitle: {
    height: 10,
    width: '35%',
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonAmounts: {
    height: 28,
    width: 60,
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
})
