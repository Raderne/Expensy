import React, { useEffect, useRef } from 'react'
import { Animated, StyleSheet, Text, View } from 'react-native'
import Svg, { Circle, G } from 'react-native-svg'
import { TrendingDown, TrendingUp } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import type { CategorySpending } from '@/api/analytics.api'

// ─── Types ────────────────────────────────────────────────────────────────────

interface DonutChartProps {
  totalSpent: number
  percentageChange: number | null
  byCategory: CategorySpending[]
  loading?: boolean
}

interface Segment {
  color: string
  startAngle: number
  sweepAngle: number
}

// ─── Constants ────────────────────────────────────────────────────────────────

const SIZE = 220
const STROKE_WIDTH = 28
const RADIUS = (SIZE - STROKE_WIDTH) / 2
const CIRCUMFERENCE = 2 * Math.PI * RADIUS
const CENTER = SIZE / 2

// Gap between segments in degrees
const GAP_DEG = 3

// Fallback colors for when the server doesn't supply a color
const FALLBACK_COLORS = [
  Colors.purple[500],
  Colors.magenta[400],
  Colors.teal[400],
  Colors.dark.warning,
  Colors.dark.success,
  Colors.info,
  Colors.purple[400],
  Colors.magenta[500],
]

// ─── Helpers ──────────────────────────────────────────────────────────────────

function buildSegments(categories: CategorySpending[]): Segment[] {
  if (categories.length === 0) return []

  const segments: Segment[] = []
  const totalDeg = 360 - GAP_DEG * categories.length
  let cursor = -90 // start at the top

  categories.forEach((cat, idx) => {
    const sweep = (cat.percentage / 100) * totalDeg
    segments.push({
      color: cat.categoryColor || FALLBACK_COLORS[idx % FALLBACK_COLORS.length],
      startAngle: cursor,
      sweepAngle: sweep,
    })
    cursor += sweep + GAP_DEG
  })

  return segments
}

function polarToCartesian(
  cx: number,
  cy: number,
  r: number,
  angleDeg: number,
): { x: number; y: number } {
  const rad = ((angleDeg - 90) * Math.PI) / 180
  return {
    x: cx + r * Math.cos(rad),
    y: cy + r * Math.sin(rad),
  }
}

/**
 * Returns the SVG strokeDashoffset and strokeDasharray values that paint
 * a circular arc from startAngle covering sweepAngle degrees.
 *
 * We draw a full circle (dasharray = circumference) and then offset it
 * so only the desired slice is visible.
 */
function arcDash(startAngle: number, sweepAngle: number): { dashOffset: number; dashArray: string } {
  const startFraction = ((startAngle + 90) / 360 + 1) % 1
  const sweepFraction = sweepAngle / 360
  const dashLength = sweepFraction * CIRCUMFERENCE
  const dashOffset = -startFraction * CIRCUMFERENCE

  return {
    dashArray: `${dashLength} ${CIRCUMFERENCE - dashLength}`,
    dashOffset,
  }
}

function formatAmount(amount: number): string {
  if (amount >= 1000) {
    return `$${(amount / 1000).toFixed(1)}k`
  }
  return `$${amount.toFixed(0)}`
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

function DonutSkeleton() {
  const pulse = useRef(new Animated.Value(0.4)).current

  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 1, duration: 800, useNativeDriver: true }),
        Animated.timing(pulse, { toValue: 0.4, duration: 800, useNativeDriver: true }),
      ]),
    ).start()
  }, [pulse])

  return (
    <Animated.View style={[styles.skeletonRing, { opacity: pulse }]} />
  )
}

// ─── Component ────────────────────────────────────────────────────────────────

export function DonutChart({ totalSpent, percentageChange, byCategory, loading = false }: DonutChartProps) {
  const rotateAnim = useRef(new Animated.Value(0)).current

  useEffect(() => {
    rotateAnim.setValue(0)
    Animated.timing(rotateAnim, {
      toValue: 1,
      duration: 600,
      useNativeDriver: true,
    }).start()
  }, [byCategory, rotateAnim])

  if (loading) {
    return (
      <View style={styles.wrapper}>
        <DonutSkeleton />
        <View style={styles.centerLabelSkeleton} />
      </View>
    )
  }

  const isEmpty = byCategory.length === 0
  const segments = isEmpty ? [] : buildSegments(byCategory)

  // spending less than last period = improvement = green (negative % change)
  const isImprovement = percentageChange !== null && percentageChange <= 0
  const changeBadgeColor = isImprovement ? Colors.dark.success : Colors.dark.danger
  const changeBgColor = isImprovement ? 'rgba(34,197,94,0.15)' : 'rgba(239,68,68,0.15)'
  const changeSign = percentageChange !== null && percentageChange > 0 ? '+' : ''

  return (
    <View style={styles.wrapper}>
      {/* SVG donut */}
      <View style={styles.chartContainer}>
        <Svg width={SIZE} height={SIZE}>
          <G>
            {/* Track ring */}
            <Circle
              cx={CENTER}
              cy={CENTER}
              r={RADIUS}
              fill="none"
              stroke={Colors.bg.elevated}
              strokeWidth={STROKE_WIDTH}
            />
            {isEmpty ? (
              /* Empty state ring */
              <Circle
                cx={CENTER}
                cy={CENTER}
                r={RADIUS}
                fill="none"
                stroke={Colors.border.default}
                strokeWidth={STROKE_WIDTH}
                strokeDasharray={`${CIRCUMFERENCE * 0.92} ${CIRCUMFERENCE * 0.08}`}
                strokeDashoffset={0}
                strokeLinecap="round"
              />
            ) : (
              segments.map((seg, idx) => {
                const { dashArray, dashOffset } = arcDash(seg.startAngle, seg.sweepAngle)
                return (
                  <Circle
                    key={idx}
                    cx={CENTER}
                    cy={CENTER}
                    r={RADIUS}
                    fill="none"
                    stroke={seg.color}
                    strokeWidth={STROKE_WIDTH}
                    strokeDasharray={dashArray}
                    strokeDashoffset={dashOffset}
                    strokeLinecap="butt"
                  />
                )
              })
            )}
          </G>
        </Svg>

        {/* Center label — positioned absolutely over the SVG */}
        <View style={styles.centerLabel} pointerEvents="none">
          {isEmpty ? (
            <Text style={styles.emptyText}>No data</Text>
          ) : (
            <>
              <Text style={styles.totalLabel}>TOTAL SPENT</Text>
              <Text style={styles.totalAmount}>{formatAmount(totalSpent)}</Text>
              {percentageChange !== null && (
                <View style={[styles.changeBadge, { backgroundColor: changeBgColor }]}>
                  {isImprovement ? (
                    <TrendingDown size={11} color={changeBadgeColor} strokeWidth={2.5} />
                  ) : (
                    <TrendingUp size={11} color={changeBadgeColor} strokeWidth={2.5} />
                  )}
                  <Text style={[styles.changeText, { color: changeBadgeColor }]}>
                    {changeSign}{Math.abs(percentageChange).toFixed(1)}%
                  </Text>
                </View>
              )}
            </>
          )}
        </View>
      </View>
    </View>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  wrapper: {
    alignItems: 'center',
    paddingVertical: 8,
  },
  chartContainer: {
    width: SIZE,
    height: SIZE,
    alignItems: 'center',
    justifyContent: 'center',
  },
  centerLabel: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
    width: SIZE - STROKE_WIDTH * 2 - 16,
  },
  totalLabel: {
    fontSize: 10,
    fontWeight: '600',
    color: Colors.dark.text.muted,
    letterSpacing: 1,
    marginBottom: 4,
  },
  totalAmount: {
    fontSize: 30,
    fontWeight: '700',
    color: Colors.dark.text.primary,
    letterSpacing: -0.5,
    fontVariant: ['tabular-nums'],
  },
  changeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 100,
    marginTop: 6,
  },
  changeText: {
    fontSize: 11,
    fontWeight: '600',
  },
  emptyText: {
    fontSize: 15,
    fontWeight: '500',
    color: Colors.dark.text.muted,
  },
  // Skeleton
  skeletonRing: {
    width: SIZE,
    height: SIZE,
    borderRadius: SIZE / 2,
    borderWidth: STROKE_WIDTH,
    borderColor: Colors.bg.elevated,
  },
  centerLabelSkeleton: {
    position: 'absolute',
    width: 80,
    height: 20,
    borderRadius: 6,
    backgroundColor: Colors.bg.elevated,
  },
})
