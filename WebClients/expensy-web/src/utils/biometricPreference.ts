import * as SecureStore from 'expo-secure-store'

const BIOMETRIC_ENABLED_KEY = 'expensy_biometric_enabled'
const BIOMETRIC_USER_ID_KEY = 'expensy_biometric_user_id'
const BIOMETRIC_REFRESH_KEY = 'expensy_biometric_refresh_token'

export const getBiometricEnabled = (): Promise<boolean> =>
  SecureStore.getItemAsync(BIOMETRIC_ENABLED_KEY).then((v) => v === 'true')

export const setBiometricEnabled = (enabled: boolean): Promise<void> =>
  SecureStore.setItemAsync(BIOMETRIC_ENABLED_KEY, enabled ? 'true' : 'false')

/** Snapshot the current session for biometric re-auth. Survives logout. */
export const saveBiometricSession = (userId: string, refreshToken: string): Promise<void> =>
  Promise.all([
    SecureStore.setItemAsync(BIOMETRIC_USER_ID_KEY, userId),
    SecureStore.setItemAsync(BIOMETRIC_REFRESH_KEY, refreshToken),
  ]).then(() => {})

/** Read the stored biometric session. Returns null if not set. */
export const getBiometricSession = async (): Promise<{ userId: string; refreshToken: string } | null> => {
  const [userId, refreshToken] = await Promise.all([
    SecureStore.getItemAsync(BIOMETRIC_USER_ID_KEY),
    SecureStore.getItemAsync(BIOMETRIC_REFRESH_KEY),
  ])
  if (!userId || !refreshToken) return null
  return { userId, refreshToken }
}

/** Remove the biometric session (called when user disables the toggle). */
export const clearBiometricSession = (): Promise<void> =>
  Promise.all([
    SecureStore.deleteItemAsync(BIOMETRIC_USER_ID_KEY),
    SecureStore.deleteItemAsync(BIOMETRIC_REFRESH_KEY),
  ]).then(() => {})
