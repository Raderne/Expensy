import React, { useCallback } from 'react'
import {
  Alert,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { router } from 'expo-router'
import { ArrowLeft, Bell } from 'lucide-react-native'
import { Colors } from '@/constants/colors'
import {
  useNotifications,
  useMarkNotificationAsRead,
  useMarkAllNotificationsAsRead,
  useDeleteNotification,
} from '@/hooks/useNotifications'
import { NotificationItem } from '@/components/notifications/NotificationItem'
import type { NotificationDto } from '@/api/types'

// ─── Empty State ──────────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <View style={styles.emptyContainer}>
      <View style={styles.emptyIconWrap}>
        <Bell size={40} color={Colors.purple[400]} strokeWidth={1.5} />
      </View>
      <Text style={styles.emptyTitle}>You're all caught up</Text>
      <Text style={styles.emptySubtitle}>
        No notifications right now. Check back later.
      </Text>
    </View>
  )
}

// ─── Error State ──────────────────────────────────────────────────────────────

function ErrorState({ onRetry }: { onRetry: () => void }) {
  return (
    <View style={styles.emptyContainer}>
      <Text style={styles.emptyTitle}>Something went wrong</Text>
      <Text style={styles.emptySubtitle}>
        Could not load notifications. Please try again.
      </Text>
      <TouchableOpacity
        style={styles.retryButton}
        onPress={onRetry}
        activeOpacity={0.75}
        accessibilityRole="button"
        accessibilityLabel="Retry loading notifications"
      >
        <Text style={styles.retryText}>Retry</Text>
      </TouchableOpacity>
    </View>
  )
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

function NotificationSkeleton() {
  return (
    <View style={styles.skeletonItem}>
      <View style={styles.skeletonDot} />
      <View style={styles.skeletonContent}>
        <View style={styles.skeletonTitle} />
        <View style={styles.skeletonBody} />
        <View style={styles.skeletonTime} />
      </View>
    </View>
  )
}

// ─── Deletable Notification Item ──────────────────────────────────────────────

interface DeletableNotificationItemProps {
  notification: NotificationDto
  onPress: (id: string) => void
  onDelete: (id: string) => void
}

function DeletableNotificationItem({
  notification,
  onPress,
  onDelete,
}: DeletableNotificationItemProps) {
  function handleLongPress() {
    if (!notification.id) return

    const id = notification.id
    Alert.alert(
      'Delete Notification',
      'Remove this notification?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => onDelete(id),
        },
      ],
      { cancelable: true },
    )
  }

  return (
    <NotificationItem
      notification={notification}
      onPress={onPress}
      onLongPress={handleLongPress}
    />
  )
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function NotificationsScreen() {
  const { data, isLoading, isError, refetch } = useNotifications()
  const { mutate: markAsRead } = useMarkNotificationAsRead()
  const { mutate: markAllAsRead, isPending: isMarkingAll } = useMarkAllNotificationsAsRead()
  const { mutate: deleteNotification } = useDeleteNotification()

  const onRefresh = useCallback(() => {
    refetch()
  }, [refetch])

  // data is NotificationPagedResult — items is the list, unreadCount is the badge
  const items = data?.items ?? []

  // Sort newest first
  const sorted = [...items].sort((a, b) => {
    const tA = a.created ? new Date(a.created).getTime() : 0
    const tB = b.created ? new Date(b.created).getTime() : 0
    return tB - tA
  })

  const isEmpty = !isLoading && !isError && sorted.length === 0
  const hasUnread = sorted.some((n) => !n.isRead)

  function handleMarkAllRead() {
    if (!isMarkingAll) {
      markAllAsRead()
    }
  }

  function handleItemPress(id: string) {
    markAsRead(id)
  }

  function handleItemDelete(id: string) {
    deleteNotification(id)
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => router.back()}
          activeOpacity={0.75}
          accessibilityRole="button"
          accessibilityLabel="Go back"
        >
          <ArrowLeft size={20} color={Colors.dark.text.primary} strokeWidth={2} />
        </TouchableOpacity>

        <Text style={styles.headerTitle}>Notifications</Text>

        <TouchableOpacity
          onPress={handleMarkAllRead}
          activeOpacity={hasUnread && !isMarkingAll ? 0.75 : 1}
          disabled={!hasUnread || isMarkingAll}
          accessibilityRole="button"
          accessibilityLabel="Mark all notifications as read"
        >
          <Text
            style={[
              styles.markAllText,
              (!hasUnread || isMarkingAll) && styles.markAllTextDisabled,
            ]}
          >
            Mark all read
          </Text>
        </TouchableOpacity>
      </View>

      {/* ── Content ── */}
      {isError ? (
        <ErrorState onRetry={refetch} />
      ) : (
        <ScrollView
          style={styles.scroll}
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl
              refreshing={isLoading}
              onRefresh={onRefresh}
              tintColor={Colors.purple[500]}
              colors={[Colors.purple[500]]}
            />
          }
        >
          {isLoading ? (
            Array.from({ length: 5 }).map((_, i) => <NotificationSkeleton key={i} />)
          ) : isEmpty ? (
            <EmptyState />
          ) : (
            sorted.map((notification) => (
              <DeletableNotificationItem
                key={notification.id}
                notification={notification}
                onPress={handleItemPress}
                onDelete={handleItemDelete}
              />
            ))
          )}

          <View style={styles.bottomSpacer} />
        </ScrollView>
      )}
    </SafeAreaView>
  )
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: Colors.bg.base,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 12,
    gap: 12,
  },
  backButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Colors.bg.elevated,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: Colors.dark.border.subtle,
  },
  headerTitle: {
    flex: 1,
    fontSize: 22,
    fontWeight: '700',
    color: Colors.dark.text.primary,
  },
  markAllText: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.purple[500],
  },
  markAllTextDisabled: {
    color: Colors.dark.text.muted,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 20,
  },
  // Skeleton
  skeletonItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingHorizontal: 20,
    paddingVertical: 14,
    gap: 12,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border.subtle,
  },
  skeletonDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.bg.overlay,
    marginTop: 4,
  },
  skeletonContent: {
    flex: 1,
    gap: 6,
  },
  skeletonTitle: {
    height: 13,
    width: '65%',
    borderRadius: 4,
    backgroundColor: Colors.bg.elevated,
  },
  skeletonBody: {
    height: 11,
    width: '85%',
    borderRadius: 4,
    backgroundColor: Colors.bg.elevated,
  },
  skeletonTime: {
    height: 10,
    width: '30%',
    borderRadius: 4,
    backgroundColor: Colors.bg.elevated,
    marginTop: 2,
  },
  // Empty / Error
  emptyContainer: {
    alignItems: 'center',
    paddingHorizontal: 40,
    paddingTop: 80,
    gap: 10,
  },
  emptyIconWrap: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: Colors.bg.elevated,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 4,
  },
  emptyTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.dark.text.primary,
    textAlign: 'center',
  },
  emptySubtitle: {
    fontSize: 13,
    color: Colors.dark.text.muted,
    textAlign: 'center',
    lineHeight: 20,
  },
  retryButton: {
    marginTop: 6,
    paddingHorizontal: 24,
    paddingVertical: 10,
    borderRadius: 10,
    backgroundColor: Colors.purple[600],
  },
  retryText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  bottomSpacer: {
    height: 24,
  },
})
