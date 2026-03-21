import React from 'react'
import { StyleSheet, Text, View } from 'react-native'
import { Colors } from '@/constants/colors'

// ─── Types ────────────────────────────────────────────────────────────────────

interface SettingsGroupProps {
  title: string
  children: React.ReactNode
}

// ─── Component ────────────────────────────────────────────────────────────────

export function SettingsGroup({ title, children }: SettingsGroupProps) {
  const childArray = React.Children.toArray(children).filter(Boolean)
  const count = childArray.length

  const childrenWithPosition = childArray.map((child, index) => {
    if (!React.isValidElement(child)) return child

    let position: 'first' | 'middle' | 'last' | 'only'
    if (count === 1) {
      position = 'only'
    } else if (index === 0) {
      position = 'first'
    } else if (index === count - 1) {
      position = 'last'
    } else {
      position = 'middle'
    }

    return React.cloneElement(child as React.ReactElement<{ position?: string }>, { position })
  })

  return (
    <View style={styles.group}>
      <Text style={styles.title}>{title.toUpperCase()}</Text>
      <View style={styles.card}>{childrenWithPosition}</View>
    </View>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  group: {
    gap: 8,
  },
  title: {
    fontSize: 11,
    fontWeight: '600',
    color: Colors.text.muted,
    letterSpacing: 1,
    paddingHorizontal: 4,
  },
  card: {
    borderRadius: 14,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Colors.border.subtle,
  },
})
