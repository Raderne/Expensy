import React from 'react'
import { StyleSheet, Text, View } from 'react-native'
import { Colors } from '@/constants/colors'

interface DayData {
  day: string   // 'M' | 'T' | 'W' | 'T' | 'F' | 'S' | 'S'
  amount: number
}

interface WeeklySpendingChartProps {
  data?: DayData[]
  loading?: boolean
}

const DAY_LABELS = ['M', 'T', 'W', 'T', 'F', 'S', 'S']

// Get today's index in the M-S week (0=Monday ... 6=Sunday)
function getTodayIndex(): number {
  const jsDay = new Date().getDay() // 0=Sun, 1=Mon...
  return jsDay === 0 ? 6 : jsDay - 1
}

// Generate placeholder data so chart renders even with no server data
function buildPlaceholder(): DayData[] {
  return DAY_LABELS.map((day, i) => ({
    day,
    amount: 20 + Math.floor(Math.sin(i) * 10 + 10),
  }))
}

const BAR_MAX_HEIGHT = 64
const BAR_MIN_HEIGHT = 8

export function WeeklySpendingChart({ data, loading = false }: WeeklySpendingChartProps) {
  const todayIndex = getTodayIndex()
  const chartData = data && data.length === 7 ? data : buildPlaceholder()
  const maxAmount = Math.max(...chartData.map((d) => d.amount), 1)

  return (
    <View style={styles.container}>
      <View style={styles.bars}>
        {chartData.map((item, index) => {
          const isToday = index === todayIndex
          const heightRatio = item.amount / maxAmount
          const barHeight = Math.max(
            BAR_MIN_HEIGHT,
            Math.round(heightRatio * BAR_MAX_HEIGHT),
          )

          return (
            <View key={index} style={styles.barColumn}>
              <View style={styles.barTrack}>
                {loading ? (
                  <View
                    style={[
                      styles.bar,
                      styles.barSkeleton,
                      { height: BAR_MAX_HEIGHT * 0.4 },
                    ]}
                  />
                ) : (
                  <View
                    style={[
                      styles.bar,
                      isToday ? styles.barToday : styles.barDefault,
                      { height: barHeight },
                    ]}
                  />
                )}
              </View>
              <Text
                style={[
                  styles.dayLabel,
                  isToday && styles.dayLabelToday,
                ]}
              >
                {item.day}
              </Text>
            </View>
          )
        })}
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    paddingTop: 8,
    paddingBottom: 4,
  },
  bars: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    paddingHorizontal: 8,
  },
  barColumn: {
    flex: 1,
    alignItems: 'center',
    gap: 6,
  },
  barTrack: {
    height: BAR_MAX_HEIGHT,
    justifyContent: 'flex-end',
    alignItems: 'center',
  },
  bar: {
    width: 24,
    borderRadius: 6,
  },
  barDefault: {
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.dark.border.default,
  },
  barToday: {
    backgroundColor: Colors.purple[500],
  },
  barSkeleton: {
    backgroundColor: Colors.bg.elevated,
    opacity: 0.5,
  },
  dayLabel: {
    fontSize: 11,
    fontWeight: '500',
    color: Colors.dark.text.muted,
  },
  dayLabelToday: {
    color: Colors.purple[500],
    fontWeight: '700',
  },
})
