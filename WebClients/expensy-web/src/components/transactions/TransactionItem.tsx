import React, { useEffect, useRef } from 'react'
import { Animated, StyleSheet, Text, TouchableOpacity, View } from 'react-native'
import { Trash2 } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import type { TransactionDto } from '@/api/types'

// ─── Types ────────────────────────────────────────────────────────────────────

interface TransactionItemProps {
  transaction: TransactionDto
  onDelete?: (id: string) => void
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount)
}

function formatDate(date: Date | undefined): string {
  if (!date) return ''
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
  }).format(new Date(date))
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

export function TransactionItemSkeleton() {
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
    <Animated.View style={[styles.row, { opacity: pulse }]}>
      <View style={styles.skeletonIcon} />
      <View style={styles.centerGroup}>
        <View style={styles.skeletonTitle} />
        <View style={styles.skeletonSubtitle} />
      </View>
      <View style={styles.skeletonAmount} />
    </Animated.View>
  )
}

// ─── Component ────────────────────────────────────────────────────────────────

export function TransactionItem({ transaction, onDelete }: TransactionItemProps) {
  const iconBg = transaction.categoryColor
    ? `${transaction.categoryColor}22`
    : `${Colors.purple[500]}22`
  const iconColor = transaction.categoryColor ?? Colors.purple[500]

  const subParts: string[] = []
  if (transaction.categoryName) subParts.push(transaction.categoryName)
  if (transaction.paymentMethod) subParts.push(transaction.paymentMethod)
  if (transaction.transactionDate) subParts.push(formatDate(transaction.transactionDate))
  const subtitle = subParts.join(' · ')

  return (
    <View style={styles.row}>
      {/* Icon circle */}
      <View style={[styles.iconCircle, { backgroundColor: iconBg }]}>
        <Text style={[styles.iconText, { color: iconColor }]}>
          {transaction.categoryIcon ?? transaction.categoryName?.charAt(0).toUpperCase() ?? '?'}
        </Text>
      </View>

      {/* Center */}
      <View style={styles.centerGroup}>
        <Text style={styles.merchant} numberOfLines={1}>
          {transaction.merchantName ?? 'Unknown merchant'}
        </Text>
        {subtitle ? (
          <Text style={styles.subtitle} numberOfLines={1}>
            {subtitle}
          </Text>
        ) : null}
      </View>

      {/* Right: amount + optional delete */}
      <View style={styles.rightGroup}>
        <Text style={styles.amount}>
          -{formatCurrency(transaction.amount ?? 0)}
        </Text>
        {onDelete && transaction.id ? (
          <TouchableOpacity
            style={styles.deleteBtn}
            onPress={() => onDelete(transaction.id!)}
            activeOpacity={0.7}
            accessibilityRole="button"
            accessibilityLabel={`Delete transaction from ${transaction.merchantName}`}
          >
            <Trash2 size={14} color={Colors.danger} strokeWidth={2} />
          </TouchableOpacity>
        ) : null}
      </View>
    </View>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
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
  merchant: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.text.primary,
  },
  subtitle: {
    fontSize: 12,
    color: Colors.text.muted,
    fontWeight: '500',
  },
  rightGroup: {
    alignItems: 'flex-end',
    gap: 4,
    flexShrink: 0,
  },
  amount: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.danger,
  },
  deleteBtn: {
    width: 26,
    height: 26,
    borderRadius: 7,
    backgroundColor: `${Colors.danger}18`,
    alignItems: 'center',
    justifyContent: 'center',
  },
  // Skeleton
  skeletonIcon: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: Colors.bg.overlay,
    flexShrink: 0,
  },
  skeletonTitle: {
    height: 13,
    width: '60%',
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonSubtitle: {
    height: 10,
    width: '40%',
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonAmount: {
    height: 13,
    width: 60,
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
})
