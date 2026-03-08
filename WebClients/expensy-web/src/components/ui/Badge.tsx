import React from 'react'
import { StyleSheet, Text, View, ViewStyle } from 'react-native'
import { Colors } from '@/constants/colors'

type BadgeVariant = 'success' | 'danger' | 'warning' | 'info' | 'purple'

interface BadgeProps {
  label: string
  variant?: BadgeVariant
  style?: ViewStyle
}

const VARIANT_COLORS: Record<BadgeVariant, { bg: string; text: string }> = {
  success: { bg: 'rgba(34,197,94,0.15)', text: Colors.dark.success },
  danger: { bg: 'rgba(239,68,68,0.15)', text: Colors.dark.danger },
  warning: { bg: 'rgba(249,115,22,0.15)', text: Colors.dark.warning },
  info: { bg: 'rgba(156,163,175,0.15)', text: Colors.dark.text.secondary },
  purple: { bg: 'rgba(176,78,255,0.15)', text: Colors.purple[500] },
}

export function Badge({ label, variant = 'info', style }: BadgeProps) {
  const { bg, text } = VARIANT_COLORS[variant]
  return (
    <View style={[styles.base, { backgroundColor: bg }, style]}>
      <Text style={[styles.label, { color: text }]}>{label}</Text>
    </View>
  )
}

const styles = StyleSheet.create({
  base: {
    borderRadius: 100,
    paddingHorizontal: 10,
    paddingVertical: 4,
    alignSelf: 'flex-start',
  },
  label: {
    fontSize: 12,
    fontWeight: '600',
  },
})
