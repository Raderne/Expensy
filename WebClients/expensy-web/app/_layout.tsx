import React, { useEffect } from 'react'
import axios from 'axios'
import { Slot, useRouter } from 'expo-router'
import { SafeAreaProvider } from 'react-native-safe-area-context'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import * as SecureStore from 'expo-secure-store'
import { useAuthStore, getStoredRefreshToken, getStoredUserId } from '@/store/auth.store'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'

// Android emulator: 10.0.2.2 → host machine. iOS simulator: use localhost.
const API_BASE = 'http://10.0.2.2:5118/api'

const ONBOARDING_KEY = 'expensy_onboarding_done'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 2 * 60 * 1000,     // 2 minutes
      gcTime: 10 * 60 * 1000,       // 10 minutes
      refetchOnWindowFocus: false,
    },
  },
})

interface RefreshResponse {
  accessToken: string
  refreshToken: string
  userId: string
  email: string
}

export default function RootLayout() {
  const { setAuth, clearAuth, setInitialized, isInitialized, isAuthenticated } = useAuthStore()
  const router = useRouter()

  useEffect(() => {
    async function hydrate() {
      try {
        const [refreshToken, userId] = await Promise.all([
          getStoredRefreshToken(),
          getStoredUserId(),
        ])

        if (refreshToken && userId) {
          // Use a plain axios call (not apiClient) to avoid triggering the
          // 401 interceptor recursively during app boot before the router mounts.
          const { data } = await axios.post<RefreshResponse>(
            `${API_BASE}/auth/refresh`,
            { userId, refreshToken },
            { headers: { 'Content-Type': 'application/json' } },
          )
          await setAuth(
            { id: data.userId, email: data.email },
            data.accessToken,
            data.refreshToken,
          )
        } else {
          await clearAuth()
        }
      } catch {
        // Token expired or invalid — clear and let the auth guard redirect to login
        await clearAuth()
      } finally {
        setInitialized()
      }
    }

    hydrate()
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (!isInitialized) return

    async function navigate() {
      const onboardingDone = await SecureStore.getItemAsync(ONBOARDING_KEY)

      if (!onboardingDone) {
        router.replace('/onboarding')
      } else if (isAuthenticated) {
        router.replace('/(app)')
      } else {
        router.replace('/(auth)/login')
      }
    }

    navigate()
  // router is stable across renders; isInitialized and isAuthenticated are the real deps
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isInitialized])

  if (!isInitialized) {
    return <LoadingSpinner />
  }

  return (
    <QueryClientProvider client={queryClient}>
      <SafeAreaProvider>
        <Slot />
      </SafeAreaProvider>
    </QueryClientProvider>
  )
}
