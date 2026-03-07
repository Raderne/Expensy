import { create } from 'zustand'
import * as SecureStore from 'expo-secure-store'

const REFRESH_TOKEN_KEY = 'expensy_refresh_token'
const USER_ID_KEY = 'expensy_user_id'

export interface AuthUser {
  id: string
  email: string
}

interface AuthState {
  user: AuthUser | null
  accessToken: string | null
  isAuthenticated: boolean
  isInitialized: boolean
  setAuth: (user: AuthUser, accessToken: string, refreshToken: string) => Promise<void>
  clearAuth: () => Promise<void>
  setInitialized: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  accessToken: null,
  isAuthenticated: false,
  isInitialized: false,

  setAuth: async (user, accessToken, refreshToken) => {
    await SecureStore.setItemAsync(REFRESH_TOKEN_KEY, refreshToken)
    await SecureStore.setItemAsync(USER_ID_KEY, user.id)
    set({ user, accessToken, isAuthenticated: true })
  },

  clearAuth: async () => {
    await SecureStore.deleteItemAsync(REFRESH_TOKEN_KEY)
    await SecureStore.deleteItemAsync(USER_ID_KEY)
    set({ user: null, accessToken: null, isAuthenticated: false })
  },

  setInitialized: () => set({ isInitialized: true }),
}))

// Helpers for reading persisted tokens outside the store (e.g. in the API client)
export const getStoredRefreshToken = (): Promise<string | null> =>
  SecureStore.getItemAsync(REFRESH_TOKEN_KEY)

export const getStoredUserId = (): Promise<string | null> =>
  SecureStore.getItemAsync(USER_ID_KEY)
