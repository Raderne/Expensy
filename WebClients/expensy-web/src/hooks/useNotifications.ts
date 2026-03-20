import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { notificationsClient } from '@/api/clients';
import type { NotificationPagedResult } from '@/api/types';

export const NOTIFICATIONS_QUERY_KEY = ['notifications'] as const;
export const NOTIFICATIONS_UNREAD_COUNT_KEY = ['notifications', 'unread-count'] as const;

// ─── List ─────────────────────────────────────────────────────────────────────

export function useNotifications() {
  return useQuery<NotificationPagedResult, Error>({
    queryKey: NOTIFICATIONS_QUERY_KEY,
    queryFn: () => notificationsClient.getAll(1, 20),
    staleTime: 1 * 60 * 1000, // 1 minute — notifications are more time-sensitive
    gcTime: 5 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  });
}

// ─── Unread count ─────────────────────────────────────────────────────────────

// getUnreadCount returns `any` in the generated client because the backend
// response shape is not typed. We cast defensively and default to 0.
export function useNotificationsUnreadCount() {
  return useQuery<number, Error>({
    queryKey: NOTIFICATIONS_UNREAD_COUNT_KEY,
    queryFn: async () => {
      const result: unknown = await notificationsClient.getUnreadCount();
      if (typeof result === 'number') return result;
      if (result !== null && typeof result === 'object' && 'count' in result) {
        return (result as { count: number }).count;
      }
      return 0;
    },
    staleTime: 1 * 60 * 1000,
    gcTime: 5 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  });
}

// ─── Mutations ────────────────────────────────────────────────────────────────

export function useMarkNotificationAsRead() {
  const queryClient = useQueryClient();

  return useMutation<void, Error, string>({
    mutationFn: (id: string) => notificationsClient.markAsRead(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_QUERY_KEY });
      void queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_UNREAD_COUNT_KEY });
    },
  });
}

export function useMarkAllNotificationsAsRead() {
  const queryClient = useQueryClient();

  return useMutation<void, Error, void>({
    mutationFn: () => notificationsClient.markAllAsRead(),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_QUERY_KEY });
      void queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_UNREAD_COUNT_KEY });
    },
  });
}

export function useDeleteNotification() {
  const queryClient = useQueryClient();

  return useMutation<void, Error, string>({
    mutationFn: (id: string) => notificationsClient.delete(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_QUERY_KEY });
      void queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_UNREAD_COUNT_KEY });
    },
  });
}
