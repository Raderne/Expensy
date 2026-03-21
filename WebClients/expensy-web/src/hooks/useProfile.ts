import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'

// ─── Types ────────────────────────────────────────────────────────────────────
// TODO: API — move these to @/api/types once api-client.ts is generated

export interface NotificationPreferences {
  budgetAlerts: boolean
  renewalReminders: boolean
  milestoneAlerts: boolean
}

export interface UserProfileDto {
  userId: string
  email: string
  fullName: string
  avatar?: string | null
  currencyCode: string
  notificationPreferences: NotificationPreferences
}

export interface UpdateProfileRequest {
  fullName: string
  currencyCode: string
}

export interface UpdateNotificationPreferencesRequest {
  budgetAlerts: boolean
  renewalReminders: boolean
  milestoneAlerts: boolean
}

export interface CurrencyDto {
  code: string
  name: string
  symbol: string
}

// ─── Query keys ───────────────────────────────────────────────────────────────

export const PROFILE_QUERY_KEY = ['profile'] as const
export const CURRENCIES_QUERY_KEY = ['currencies'] as const

// ─── Mock data ────────────────────────────────────────────────────────────────
// TODO: API — remove mock data once api-client.ts is generated

const MOCK_PROFILE: UserProfileDto = {
  userId: 'mock-user-id',
  email: 'user@example.com',
  fullName: 'Alex Johnson',
  avatar: null,
  currencyCode: 'USD',
  notificationPreferences: {
    budgetAlerts: true,
    renewalReminders: true,
    milestoneAlerts: false,
  },
}

const MOCK_CURRENCIES: CurrencyDto[] = [
  { code: 'USD', name: 'US Dollar', symbol: '$' },
  { code: 'EUR', name: 'Euro', symbol: '€' },
  { code: 'GBP', name: 'British Pound', symbol: '£' },
  { code: 'JPY', name: 'Japanese Yen', symbol: '¥' },
  { code: 'CAD', name: 'Canadian Dollar', symbol: 'CA$' },
  { code: 'AUD', name: 'Australian Dollar', symbol: 'A$' },
  { code: 'CHF', name: 'Swiss Franc', symbol: 'Fr' },
  { code: 'CNY', name: 'Chinese Yuan', symbol: '¥' },
]

// ─── Hooks ────────────────────────────────────────────────────────────────────

export function useProfile() {
  return useQuery<UserProfileDto, Error>({
    queryKey: PROFILE_QUERY_KEY,
    // TODO: API — replace with profileClient.getProfile() once api-client.ts is generated
    // Endpoint: GET /api/profile
    // Returns: UserProfileDto
    queryFn: () => Promise.resolve(MOCK_PROFILE),
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}

export function useUpdateProfile() {
  const queryClient = useQueryClient()

  return useMutation<UserProfileDto, Error, UpdateProfileRequest>({
    // TODO: API — replace with profileClient.updateProfile(request) once api-client.ts is generated
    // Endpoint: PUT /api/profile
    // Body: UpdateProfileRequest
    // Returns: UserProfileDto
    mutationFn: (request) =>
      Promise.resolve({ ...MOCK_PROFILE, ...request }),
    onSuccess: (updated) => {
      queryClient.setQueryData(PROFILE_QUERY_KEY, updated)
    },
  })
}

export function useUpdateNotificationPreferences() {
  const queryClient = useQueryClient()

  return useMutation<void, Error, UpdateNotificationPreferencesRequest>({
    // TODO: API — replace with profileClient.updateNotificationPreferences(request) once api-client.ts is generated
    // Endpoint: PATCH /api/profile/notification-preferences
    // Body: UpdateNotificationPreferencesRequest
    // Returns: 204 No Content
    mutationFn: (_request) => Promise.resolve(undefined),
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
    // TODO: API — replace with settingsClient.getCurrencies() once api-client.ts is generated
    // Endpoint: GET /api/settings/currencies
    // Returns: CurrencyDto[]
    queryFn: () => Promise.resolve(MOCK_CURRENCIES),
    staleTime: 30 * 60 * 1000, // currencies are stable — 30 min
    gcTime: 60 * 60 * 1000,
    retry: 1,
    refetchOnWindowFocus: false,
  })
}
