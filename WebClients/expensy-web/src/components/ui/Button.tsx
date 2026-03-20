import React from 'react'
import {
  ActivityIndicator,
  StyleSheet,
  Text,
  TouchableOpacity,
  TouchableOpacityProps,
  View,
} from 'react-native'
import { LinearGradient } from 'expo-linear-gradient'
import { Colors } from '@/constants/colors'

type Variant = 'primary' | 'mint' | 'ghost'

interface ButtonProps extends TouchableOpacityProps {
  label: string
  loading?: boolean
  variant?: Variant
}

export function Button({
  label,
  loading = false,
  variant = 'primary',
  style,
  disabled,
  ...rest
}: ButtonProps) {
  const isDisabled = disabled || loading

  const spinnerColor =
    variant === 'mint' ? Colors.text.inverse : Colors.text.primary

  // Primary uses LinearGradient as the background; wrap in TouchableOpacity
  if (variant === 'primary') {
    return (
      <TouchableOpacity
        style={[styles.base, isDisabled && styles.disabled, style]}
        disabled={isDisabled}
        activeOpacity={0.8}
        {...rest}
      >
        <LinearGradient
          colors={[Colors.purple[500], Colors.purple[600]]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
          style={StyleSheet.absoluteFill}
        />
        {loading ? (
          <ActivityIndicator size="small" color={Colors.text.primary} />
        ) : (
          <Text style={[styles.label, styles.labelPrimary]}>{label}</Text>
        )}
      </TouchableOpacity>
    )
  }

  if (variant === 'mint') {
    return (
      <TouchableOpacity
        style={[styles.base, styles.mint, isDisabled && styles.disabled, style]}
        disabled={isDisabled}
        activeOpacity={0.8}
        {...rest}
      >
        {loading ? (
          <ActivityIndicator size="small" color={spinnerColor} />
        ) : (
          <Text style={[styles.label, styles.labelMint]}>{label}</Text>
        )}
      </TouchableOpacity>
    )
  }

  // ghost variant
  return (
    <TouchableOpacity
      style={[styles.base, styles.ghost, isDisabled && styles.disabled, style]}
      disabled={isDisabled}
      activeOpacity={0.7}
      {...rest}
    >
      {loading ? (
        <ActivityIndicator size="small" color={Colors.text.primary} />
      ) : (
        <Text style={[styles.label, styles.labelGhost]}>{label}</Text>
      )}
    </TouchableOpacity>
  )
}

const styles = StyleSheet.create({
  base: {
    borderRadius: 9999,
    paddingVertical: 16,
    paddingHorizontal: 24,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  mint: {
    backgroundColor: Colors.mint[500],
  },
  ghost: {
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    borderColor: Colors.border.strong,
  },
  disabled: {
    opacity: 0.5,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    letterSpacing: 0.2,
  },
  labelPrimary: {
    color: Colors.text.primary,
  },
  labelMint: {
    color: Colors.text.inverse,
  },
  labelGhost: {
    color: Colors.text.secondary,
  },
})
