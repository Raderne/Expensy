import React from 'react'
import { StyleSheet, Text, View } from 'react-native'
import { LinearGradient } from 'expo-linear-gradient'
import { TrendingUp, TrendingDown } from 'lucide-react-native'
import { Colors } from '@/constants/colors'

interface BalanceCardProps {
  balance: number
  currency?: string
  changePercent?: number
  label?: string
  loading?: boolean
}

function formatCurrency(amount: number, currency = 'USD'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
  }).format(amount)
}

export function BalanceCard({
  balance,
  currency = 'USD',
  changePercent,
  label = 'Total Balance',
  loading = false,
}: BalanceCardProps) {
  const isPositive = (changePercent ?? 0) >= 0

  if (loading) {
    return (
      <View style={styles.skeleton} />
    )
  }

  return (
    <LinearGradient
      colors={['#3D1F5C', '#271C3B', '#1A0F2A']}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={styles.gradient}
    >
      {/* Decorative glow circles */}
      <View style={styles.glowTopRight} />
      <View style={styles.glowBottomLeft} />

      <Text style={styles.label}>{label}</Text>
      <Text style={styles.amount}>{formatCurrency(balance, currency)}</Text>

      {changePercent !== undefined && (
        <View style={[styles.chip, isPositive ? styles.chipPositive : styles.chipNegative]}>
          {isPositive ? (
            <TrendingUp size={13} color={Colors.dark.success} strokeWidth={2.5} />
          ) : (
            <TrendingDown size={13} color={Colors.dark.danger} strokeWidth={2.5} />
          )}
          <Text style={[styles.chipText, isPositive ? styles.chipTextPositive : styles.chipTextNegative]}>
            {isPositive ? '+' : ''}{changePercent.toFixed(1)}% vs last month
          </Text>
        </View>
      )}
    </LinearGradient>
  )
}

const styles = StyleSheet.create({
  gradient: {
    borderRadius: 20,
    padding: 24,
    marginHorizontal: 16,
    overflow: 'hidden',
    minHeight: 140,
    justifyContent: 'flex-end',
  },
  skeleton: {
    height: 140,
    borderRadius: 20,
    marginHorizontal: 16,
    backgroundColor: Colors.bg.elevated,
    opacity: 0.6,
  },
  glowTopRight: {
    position: 'absolute',
    top: -30,
    right: -30,
    width: 140,
    height: 140,
    borderRadius: 70,
    backgroundColor: Colors.purple[600],
    opacity: 0.25,
  },
  glowBottomLeft: {
    position: 'absolute',
    bottom: -40,
    left: -20,
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: Colors.purple[700],
    opacity: 0.20,
  },
  label: {
    fontSize: 13,
    color: 'rgba(249,250,251,0.6)',
    fontWeight: '500',
    letterSpacing: 0.5,
    marginBottom: 6,
  },
  amount: {
    fontSize: 34,
    fontWeight: '700',
    color: Colors.dark.text.primary,
    letterSpacing: -0.5,
    marginBottom: 14,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 100,
    alignSelf: 'flex-start',
  },
  chipPositive: {
    backgroundColor: 'rgba(34,197,94,0.15)',
  },
  chipNegative: {
    backgroundColor: 'rgba(239,68,68,0.15)',
  },
  chipText: {
    fontSize: 12,
    fontWeight: '600',
  },
  chipTextPositive: {
    color: Colors.dark.success,
  },
  chipTextNegative: {
    color: Colors.dark.danger,
  },
})
