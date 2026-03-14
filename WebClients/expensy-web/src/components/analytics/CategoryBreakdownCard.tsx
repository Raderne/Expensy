import React, { useEffect, useRef } from 'react'
import { Animated, StyleSheet, Text, View } from 'react-native'
import { Colors } from '@/constants/colors'
import type { CategorySpending } from '@/api/analytics.api'

// ─── Types ────────────────────────────────────────────────────────────────────

interface CategoryBreakdownCardProps {
  item: CategorySpending
  index: number
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

// ─── Skeleton ─────────────────────────────────────────────────────────────────

export function CategoryBreakdownCardSkeleton() {
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
      <View style={styles.skeletonRow}>
        <View style={styles.skeletonIcon} />
        <View style={styles.skeletonTextGroup}>
          <View style={styles.skeletonTitle} />
          <View style={styles.skeletonSubtitle} />
        </View>
        <View style={styles.skeletonPercent} />
      </View>
      <View style={styles.barTrack}>
        <View style={[styles.bar, { width: '30%', backgroundColor: Colors.bg.overlay }]} />
      </View>
    </Animated.View>
  )
}

// ─── Component ────────────────────────────────────────────────────────────────

export function CategoryBreakdownCard({ item, index }: CategoryBreakdownCardProps) {
  const barWidth = useRef(new Animated.Value(0)).current

  useEffect(() => {
    // Stagger each card's animation slightly for a cascade effect
    const delay = index * 60
    barWidth.setValue(0)
    Animated.timing(barWidth, {
      toValue: item.percentage,
      duration: 700,
      delay,
      useNativeDriver: false, // width % cannot use native driver
    }).start()
  }, [item.percentage, index, barWidth])

  const animatedWidth = barWidth.interpolate({
    inputRange: [0, 100],
    outputRange: ['0%', '100%'],
  })

  return (
    <View style={styles.card}>
      {/* Top row */}
      <View style={styles.row}>
        {/* Color dot + name */}
        <View style={styles.left}>
          <View style={[styles.dot, { backgroundColor: item.categoryColor }]} />
          <View style={styles.textGroup}>
            <Text style={styles.categoryName} numberOfLines={1}>
              {item.categoryName}
            </Text>
            <Text style={styles.amount}>{formatCurrency(item.amount)}</Text>
          </View>
        </View>

        {/* Percentage */}
        <Text style={styles.percentage}>{item.percentage.toFixed(1)}%</Text>
      </View>

      {/* Animated progress bar */}
      <View style={styles.barTrack}>
        <Animated.View
          style={[
            styles.bar,
            { width: animatedWidth, backgroundColor: item.categoryColor },
          ]}
        />
      </View>
    </View>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.bg.elevated,
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingTop: 14,
    paddingBottom: 12,
    borderWidth: 1,
    borderColor: Colors.border.subtle,
    gap: 10,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  left: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  dot: {
    width: 36,
    height: 36,
    borderRadius: 18,
    opacity: 0.9,
  },
  textGroup: {
    flex: 1,
    gap: 2,
  },
  categoryName: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.dark.text.primary,
  },
  amount: {
    fontSize: 12,
    color: Colors.dark.text.muted,
    fontWeight: '500',
  },
  percentage: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.dark.text.primary,
    minWidth: 48,
    textAlign: 'right',
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
  // Skeleton
  skeletonRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  skeletonIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonTextGroup: {
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
    height: 11,
    width: '35%',
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonPercent: {
    width: 40,
    height: 14,
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
})
