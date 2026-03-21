import React from 'react'
import { Pressable, StyleSheet, Text, View } from 'react-native'
import { ChevronRight } from 'lucide-react-native'
import { Colors } from '@/constants/colors'

// ─── Types ────────────────────────────────────────────────────────────────────

interface SettingsRowProps {
  label: string
  description?: string
  rightElement?: React.ReactNode
  onPress?: () => void
  disabled?: boolean
  icon?: React.ReactNode
  iconColor?: string
  /** Show chevron on the right. Defaults to true when onPress is provided and no rightElement. */
  showChevron?: boolean
  /** Visual position within a group — controls which corners are rounded. Injected by SettingsGroup. */
  position?: 'first' | 'middle' | 'last' | 'only'
}

// ─── Component ────────────────────────────────────────────────────────────────

export function SettingsRow({
  label,
  description,
  rightElement,
  onPress,
  disabled = false,
  icon,
  showChevron,
  position = 'middle',
}: SettingsRowProps) {
  const shouldShowChevron =
    showChevron !== undefined ? showChevron : onPress != null && rightElement == null

  const borderRadiusStyle = getBorderRadiusStyle(position)

  const content = (
    <View style={[styles.row, borderRadiusStyle, disabled && styles.rowDisabled]}>
      {/* ── Separator above (skip for first/only) ── */}
      {position !== 'first' && position !== 'only' && (
        <View style={styles.separator} />
      )}

      <View style={styles.inner}>
        {/* ── Left icon ── */}
        {icon != null && <View style={styles.iconWrap}>{icon}</View>}

        {/* ── Label + description ── */}
        <View style={styles.labelWrap}>
          <Text
            style={[styles.label, disabled && styles.labelDisabled]}
            numberOfLines={1}
          >
            {label}
          </Text>
          {description != null && (
            <Text style={styles.description} numberOfLines={2}>
              {description}
            </Text>
          )}
        </View>

        {/* ── Right element or chevron ── */}
        <View style={styles.right}>
          {rightElement}
          {shouldShowChevron && (
            <ChevronRight
              size={16}
              color={Colors.text.muted}
              strokeWidth={2}
            />
          )}
        </View>
      </View>
    </View>
  )

  if (onPress == null || disabled) {
    return content
  }

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled }}
      style={({ pressed }) => [pressed && styles.pressed]}
    >
      {content}
    </Pressable>
  )
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getBorderRadiusStyle(position: SettingsRowProps['position']) {
  switch (position) {
    case 'first':
      return styles.radiusTop
    case 'last':
      return styles.radiusBottom
    case 'only':
      return styles.radiusAll
    default:
      return undefined
  }
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  row: {
    backgroundColor: Colors.bg.elevated,
    minHeight: 52,
  },
  rowDisabled: {
    opacity: 0.45,
  },
  radiusTop: {
    borderTopLeftRadius: 14,
    borderTopRightRadius: 14,
  },
  radiusBottom: {
    borderBottomLeftRadius: 14,
    borderBottomRightRadius: 14,
  },
  radiusAll: {
    borderRadius: 14,
  },
  separator: {
    height: 1,
    backgroundColor: Colors.border.subtle,
    marginLeft: 16,
  },
  inner: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 13,
    gap: 12,
  },
  iconWrap: {
    width: 28,
    alignItems: 'center',
    justifyContent: 'center',
  },
  labelWrap: {
    flex: 1,
    gap: 2,
  },
  label: {
    fontSize: 15,
    fontWeight: '500',
    color: Colors.text.primary,
  },
  labelDisabled: {
    color: Colors.text.muted,
  },
  description: {
    fontSize: 12,
    color: Colors.text.muted,
    lineHeight: 17,
  },
  right: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  pressed: {
    opacity: 0.7,
  },
})
