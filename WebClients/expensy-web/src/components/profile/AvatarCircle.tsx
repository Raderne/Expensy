import React from 'react'
import { Image, StyleSheet, Text, View } from 'react-native'
import { Colors } from '@/constants/colors'

// ─── Types ────────────────────────────────────────────────────────────────────

type AvatarSize = 'sm' | 'md' | 'lg'

interface AvatarCircleProps {
  name?: string | null
  avatarUrl?: string | null
  size?: AvatarSize
}

// ─── Constants ────────────────────────────────────────────────────────────────

const SIZE_MAP: Record<AvatarSize, number> = {
  sm: 32,
  md: 48,
  lg: 80,
}

const FONT_SIZE_MAP: Record<AvatarSize, number> = {
  sm: 12,
  md: 17,
  lg: 28,
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getInitials(name: string | null | undefined): string {
  if (!name) return '?'
  const parts = name.trim().split(/\s+/)
  if (parts.length === 1) return parts[0].charAt(0).toUpperCase()
  return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase()
}

// ─── Component ────────────────────────────────────────────────────────────────

export function AvatarCircle({ name, avatarUrl, size = 'md' }: AvatarCircleProps) {
  const dimension = SIZE_MAP[size]
  const fontSize = FONT_SIZE_MAP[size]

  const circleStyle = [
    styles.circle,
    { width: dimension, height: dimension, borderRadius: dimension / 2 },
  ]

  if (avatarUrl) {
    return (
      <Image
        source={{ uri: avatarUrl }}
        style={[circleStyle, styles.image]}
        accessibilityLabel={name ? `Avatar for ${name}` : 'User avatar'}
        accessibilityRole="image"
      />
    )
  }

  return (
    <View style={circleStyle} accessibilityLabel={name ? `Avatar for ${name}` : 'User avatar'}>
      <Text style={[styles.initials, { fontSize }]}>{getInitials(name)}</Text>
    </View>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  circle: {
    backgroundColor: Colors.purple[700],
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  image: {
    backgroundColor: Colors.bg.elevated,
  },
  initials: {
    color: Colors.purple[400],
    fontWeight: '700',
    letterSpacing: 0.5,
  },
})
