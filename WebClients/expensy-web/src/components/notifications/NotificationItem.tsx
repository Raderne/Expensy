import React from 'react'
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native'
import { Colors } from '@/constants/colors'
import type { NotificationDto } from '@/api/types'

// ─── Types ────────────────────────────────────────────────────────────────────

interface NotificationItemProps {
  notification: NotificationDto
  onPress?: (id: string) => void
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatRelativeTime(date: Date | undefined): string {
  if (!date) return ''

  const now = new Date()
  const d = new Date(date)
  const diffMs = now.getTime() - d.getTime()
  const diffSeconds = Math.floor(diffMs / 1000)
  const diffMinutes = Math.floor(diffSeconds / 60)
  const diffHours = Math.floor(diffMinutes / 60)
  const diffDays = Math.floor(diffHours / 24)

  if (diffSeconds < 60) return 'Just now'
  if (diffMinutes < 60) return `${diffMinutes}m ago`
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays === 1) return 'Yesterday'
  if (diffDays < 7) return `${diffDays}d ago`

  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
  }).format(d)
}

// ─── Component ────────────────────────────────────────────────────────────────

export function NotificationItem({ notification, onPress }: NotificationItemProps) {
  const isUnread = !(notification.isRead ?? true)

  function handlePress() {
    if (notification.id && onPress) {
      onPress(notification.id)
    }
  }

  return (
    <TouchableOpacity
      style={[styles.container, isUnread && styles.containerUnread]}
      onPress={handlePress}
      activeOpacity={0.75}
      accessibilityRole="button"
      accessibilityLabel={notification.title ?? 'Notification'}
    >
      {/* Left: unread dot indicator */}
      <View style={styles.dotColumn}>
        <View style={[styles.dot, isUnread ? styles.dotUnread : styles.dotRead]} />
      </View>

      {/* Center: title + body + time */}
      <View style={styles.content}>
        <Text
          style={[styles.title, isUnread && styles.titleUnread]}
          numberOfLines={2}
        >
          {notification.title ?? 'Notification'}
        </Text>
        {notification.body ? (
          <Text style={styles.body} numberOfLines={3}>
            {notification.body}
          </Text>
        ) : null}
        <Text style={styles.time}>
          {formatRelativeTime(notification.created)}
        </Text>
      </View>

      {/* Right: unread indicator dot */}
      {isUnread ? <View style={styles.unreadIndicator} /> : null}
    </TouchableOpacity>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingHorizontal: 20,
    paddingVertical: 14,
    gap: 12,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border.subtle,
  },
  containerUnread: {
    backgroundColor: `${Colors.purple[500]}08`,
  },
  dotColumn: {
    paddingTop: 3,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  dotUnread: {
    backgroundColor: Colors.purple[500],
  },
  dotRead: {
    backgroundColor: Colors.bg.overlay,
  },
  content: {
    flex: 1,
    gap: 3,
  },
  title: {
    fontSize: 14,
    fontWeight: '500',
    color: Colors.dark.text.secondary,
    lineHeight: 20,
  },
  titleUnread: {
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  body: {
    fontSize: 13,
    color: Colors.dark.text.muted,
    lineHeight: 19,
  },
  time: {
    fontSize: 12,
    color: Colors.dark.text.muted,
    fontWeight: '500',
    marginTop: 2,
  },
  unreadIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.purple[500],
    marginTop: 4,
    flexShrink: 0,
  },
})
