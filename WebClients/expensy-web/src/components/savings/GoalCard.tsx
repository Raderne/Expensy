import React, { useEffect, useRef } from 'react'
import { Animated, StyleSheet, Text, View } from 'react-native'
import { Colors } from '@/constants/colors'
import type { SavingsGoalDto, MilestoneDto } from '@/api/types'

// ─── Types ────────────────────────────────────────────────────────────────────

interface GoalCardProps {
  goal: SavingsGoalDto
  index: number
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

function formatDate(date: Date | undefined): string {
  if (!date) return '—'
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(date))
}

type MilestoneStatus = 'DONE' | 'SOON' | 'LOCKED'

function getMilestoneStatus(milestone: MilestoneDto): MilestoneStatus {
  const name = (milestone.statusName ?? '').toUpperCase()
  if (name === 'ACHIEVED' || name === 'DONE') return 'DONE'
  if (name === 'UPCOMING' || name === 'SOON' || name === 'IN_PROGRESS') return 'SOON'
  return 'LOCKED'
}

const MILESTONE_COLORS: Record<MilestoneStatus, string> = {
  DONE: Colors.dark.success,
  SOON: Colors.purple[500],
  LOCKED: Colors.dark.text.muted,
}

const MILESTONE_BG: Record<MilestoneStatus, string> = {
  DONE: 'rgba(34, 197, 94, 0.12)',
  SOON: 'rgba(176, 78, 255, 0.12)',
  LOCKED: Colors.bg.overlay,
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

export function GoalCardSkeleton() {
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
        <View style={styles.skeletonTextGroup}>
          <View style={styles.skeletonTitle} />
          <View style={styles.skeletonSubtitle} />
        </View>
      </View>
      <View style={styles.skeletonAmounts} />
      <View style={styles.barTrack}>
        <View style={[styles.bar, { width: '25%', backgroundColor: Colors.bg.overlay }]} />
      </View>
    </Animated.View>
  )
}

// ─── Component ────────────────────────────────────────────────────────────────

export function GoalCard({ goal, index }: GoalCardProps) {
  const barWidth = useRef(new Animated.Value(0)).current

  const progress = goal.progress ?? 0
  const iconColor = goal.color ?? Colors.purple[500]
  const milestones = goal.milestones ?? []

  useEffect(() => {
    const delay = index * 60
    barWidth.setValue(0)
    Animated.timing(barWidth, {
      toValue: progress,
      duration: 700,
      delay,
      useNativeDriver: false, // width % cannot use native driver
    }).start()
  }, [progress, index, barWidth])

  const animatedWidth = barWidth.interpolate({
    inputRange: [0, 100],
    outputRange: ['0%', '100%'],
  })

  return (
    <View style={styles.card}>
      {/* Top row: icon circle + name + target date */}
      <View style={styles.topRow}>
        <View style={[styles.iconCircle, { backgroundColor: `${iconColor}22` }]}>
          <Text style={[styles.iconText, { color: iconColor }]}>
            {goal.icon ?? '🎯'}
          </Text>
        </View>
        <View style={styles.nameGroup}>
          <Text style={styles.goalName} numberOfLines={1}>
            {goal.name ?? 'Unnamed Goal'}
          </Text>
          {goal.targetDate ? (
            <Text style={styles.targetDate}>Target: {formatDate(goal.targetDate)}</Text>
          ) : null}
        </View>
      </View>

      {/* Amount row */}
      <View style={styles.amountRow}>
        <Text style={styles.amounts}>
          <Text style={styles.currentAmount}>
            {formatCurrency(goal.currentAmount ?? 0)}
          </Text>
          <Text style={styles.amountSeparator}> / </Text>
          <Text style={styles.targetAmount}>
            {formatCurrency(goal.targetAmount ?? 0)}
          </Text>
        </Text>
        <Text style={[styles.progressLabel, { color: iconColor }]}>
          {progress.toFixed(1)}%
        </Text>
      </View>

      {/* Animated progress bar */}
      <View style={styles.barTrack}>
        <Animated.View
          style={[styles.bar, { width: animatedWidth, backgroundColor: iconColor }]}
        />
      </View>

      {/* Milestones row */}
      {milestones.length > 0 ? (
        <View style={styles.milestonesRow}>
          {milestones.map((m) => {
            const status = getMilestoneStatus(m)
            return (
              <View
                key={m.id}
                style={[
                  styles.milestonePill,
                  { backgroundColor: MILESTONE_BG[status] },
                ]}
              >
                <Text
                  style={[styles.milestonePillText, { color: MILESTONE_COLORS[status] }]}
                  numberOfLines={1}
                >
                  {status}
                </Text>
              </View>
            )
          })}
        </View>
      ) : null}
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
    paddingBottom: 14,
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
  },
  iconText: {
    fontSize: 20,
  },
  nameGroup: {
    flex: 1,
    gap: 2,
  },
  goalName: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  targetDate: {
    fontSize: 12,
    color: Colors.dark.text.muted,
    fontWeight: '500',
  },
  amountRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  amounts: {
    fontSize: 14,
  },
  currentAmount: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  amountSeparator: {
    fontSize: 14,
    color: Colors.dark.text.muted,
  },
  targetAmount: {
    fontSize: 14,
    fontWeight: '500',
    color: Colors.dark.text.muted,
  },
  progressLabel: {
    fontSize: 14,
    fontWeight: '700',
  },
  barTrack: {
    height: 6,
    backgroundColor: Colors.bg.overlay,
    borderRadius: 3,
    overflow: 'hidden',
  },
  bar: {
    height: 6,
    borderRadius: 3,
  },
  milestonesRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  milestonePill: {
    paddingHorizontal: 10,
    paddingVertical: 3,
    borderRadius: 20,
  },
  milestonePillText: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  // Skeleton
  skeletonIcon: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonTextGroup: {
    flex: 1,
    gap: 6,
  },
  skeletonTitle: {
    height: 14,
    width: '60%',
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonSubtitle: {
    height: 11,
    width: '40%',
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
  skeletonAmounts: {
    height: 13,
    width: '70%',
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
  },
})
