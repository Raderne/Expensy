import * as SecureStore from 'expo-secure-store'

const BIOMETRIC_ENABLED_KEY = 'expensy_biometric_enabled'

export const getBiometricEnabled = (): Promise<boolean> =>
  SecureStore.getItemAsync(BIOMETRIC_ENABLED_KEY).then((v) => v === 'true')

export const setBiometricEnabled = (enabled: boolean): Promise<void> =>
  SecureStore.setItemAsync(BIOMETRIC_ENABLED_KEY, enabled ? 'true' : 'false')
