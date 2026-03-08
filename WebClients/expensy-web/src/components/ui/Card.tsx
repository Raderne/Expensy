import React from 'react'
import { StyleSheet, View, ViewProps } from 'react-native'
import { Colors } from '@/constants/colors'

interface CardProps extends ViewProps {
  elevated?: boolean
}

export function Card({ elevated = false, style, children, ...rest }: CardProps) {
  return (
    <View
      style={[styles.base, elevated ? styles.elevated : styles.surface, style]}
      {...rest}
    >
      {children}
    </View>
  )
}

const styles = StyleSheet.create({
  base: {
    borderRadius: 16,
    padding: 16,
  },
  surface: {
    backgroundColor: Colors.bg.surface,
    borderWidth: 1,
    borderColor: Colors.dark.border.subtle,
  },
  elevated: {
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.dark.border.default,
  },
})
