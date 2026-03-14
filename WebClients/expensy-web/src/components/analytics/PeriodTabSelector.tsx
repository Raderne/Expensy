import React from 'react'
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native'
import { Colors } from '@/constants/colors'
import type { AnalyticsPeriod } from '@/hooks/useAnalytics'

// ─── Types ────────────────────────────────────────────────────────────────────

interface PeriodTab {
  label: string
  value: AnalyticsPeriod
}

interface PeriodTabSelectorProps {
  selected: AnalyticsPeriod
  onChange: (period: AnalyticsPeriod) => void
}

// ─── Constants ────────────────────────────────────────────────────────────────

const TABS: PeriodTab[] = [
  { label: 'Week', value: 'week' },
  { label: 'Month', value: 'month' },
  { label: 'Year', value: 'year' },
]

// ─── Component ────────────────────────────────────────────────────────────────

export function PeriodTabSelector({ selected, onChange }: PeriodTabSelectorProps) {
  return (
    <View style={styles.container}>
      {TABS.map((tab) => {
        const isActive = tab.value === selected
        return (
          <TouchableOpacity
            key={tab.value}
            style={[styles.tab, isActive ? styles.tabActive : styles.tabInactive]}
            onPress={() => onChange(tab.value)}
            activeOpacity={0.75}
            accessibilityRole="button"
            accessibilityLabel={`${tab.label} period`}
            accessibilityState={{ selected: isActive }}
          >
            <Text style={[styles.label, isActive ? styles.labelActive : styles.labelInactive]}>
              {tab.label}
            </Text>
          </TouchableOpacity>
        )
      })}
    </View>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    backgroundColor: Colors.bg.elevated,
    borderRadius: 12,
    padding: 4,
    gap: 4,
  },
  tab: {
    flex: 1,
    paddingVertical: 9,
    borderRadius: 9,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tabActive: {
    backgroundColor: Colors.purple[600],
  },
  tabInactive: {
    backgroundColor: 'transparent',
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
  },
  labelActive: {
    color: '#FFFFFF',
  },
  labelInactive: {
    color: Colors.dark.text.muted,
  },
})
