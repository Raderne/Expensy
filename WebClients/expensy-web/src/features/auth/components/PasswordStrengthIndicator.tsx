import React, { useMemo } from 'react'
import { StyleSheet, Text, View } from 'react-native'
import { Colors } from '@/constants/colors'

type Strength = 'weak' | 'medium' | 'strong'

function getStrength(password: string): Strength {
  let score = 0
  if (password.length >= 8) score++
  if (/[A-Z]/.test(password)) score++
  if (/[0-9]/.test(password)) score++
  if (/[^A-Za-z0-9]/.test(password)) score++

  if (score <= 1) return 'weak'
  if (score <= 2) return 'medium'
  return 'strong'
}

const STRENGTH_CONFIG: Record<Strength, { filled: number; color: string; label: string }> = {
  weak: { filled: 1, color: Colors.error, label: 'Weak' },
  medium: { filled: 2, color: Colors.warning, label: 'Medium' },
  strong: { filled: 3, color: Colors.success, label: 'Strong' },
}

interface PasswordStrengthIndicatorProps {
  password: string
}

export function PasswordStrengthIndicator({ password }: PasswordStrengthIndicatorProps) {
  const strength = useMemo(() => getStrength(password), [password])
  const { filled, color, label } = STRENGTH_CONFIG[strength]

  if (!password) return null

  return (
    <View style={styles.wrapper}>
      <View style={styles.bars}>
        {[0, 1, 2].map((i) => (
          <View
            key={i}
            style={[
              styles.bar,
              { backgroundColor: i < filled ? color : Colors.surface[200] },
            ]}
          />
        ))}
      </View>
      <Text style={[styles.label, { color }]}>{label}</Text>
    </View>
  )
}

const styles = StyleSheet.create({
  wrapper: {
    marginBottom: 16,
  },
  bars: {
    flexDirection: 'row',
    gap: 6,
    marginBottom: 4,
  },
  bar: {
    flex: 1,
    height: 4,
    borderRadius: 2,
  },
  label: {
    fontSize: 12,
    fontWeight: '500',
  },
})
