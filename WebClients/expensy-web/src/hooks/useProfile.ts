import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { profileClient, settingsClient } from '@/api/clients'
import type {
  UserProfileDto,
  UpdateProfileRequest,
  UpdateNotificationPreferencesRequest,
  CurrencyDto,
} from '@/api/types'

// ─── Query keys ───────────────────────────────────────────────────────────────

export const PROFILE_QUERY_KEY = ['profile'] as const
export const CURRENCIES_QUERY_KEY = ['currencies'] as const

// ─── Hooks ────────────────────────────────────────────────────────────────────

export function useProfile() {
  return useQuery<UserProfileDto, Error>({
    queryKey: PROFILE_QUERY_KEY,
    queryFn: () => profileClient.getProfile(),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useUpdateProfile() {
  const queryClient = useQueryClient()

  return useMutation<UserProfileDto, Error, UpdateProfileRequest>({
    mutationFn: (request) => profileClient.updateProfile(request),
    onSuccess: (updated) => {
      queryClient.setQueryData(PROFILE_QUERY_KEY, updated)
    },
  })
}

export function useUpdateNotificationPreferences() {
  const queryClient = useQueryClient()

  return useMutation<void, Error, UpdateNotificationPreferencesRequest>({
    mutationFn: (request) => profileClient.updateNotificationPreferences(request),
    onSuccess: (_data, variables) => {
      queryClient.setQueryData<UserProfileDto>(PROFILE_QUERY_KEY, (prev) => {
        if (!prev) return prev
        return { ...prev, notificationPreferences: variables }
      })
    },
  })
}

export function useCurrencies() {
  return useQuery<CurrencyDto[], Error>({
    queryKey: CURRENCIES_QUERY_KEY,
    queryFn: () => settingsClient.getCurrencies(),
    staleTime: 30 * 60 * 1000,
    gcTime: 60 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}
