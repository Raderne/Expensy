import React, { useState } from 'react'
import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { LinearGradient } from 'expo-linear-gradient'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { ArrowLeft, Check } from 'lucide-react-native'

import { registerSchema, RegisterFormValues } from '@/features/auth/schemas/auth.schema'
import { authApi } from '@/api/auth.api'
import { useAuthStore } from '@/store/auth.store'
import { AppTextInput } from '@/components/ui/AppTextInput'
import { PasswordInput } from '@/components/ui/PasswordInput'
import { PasswordStrengthIndicator } from '@/features/auth/components/PasswordStrengthIndicator'
import { Button } from '@/components/ui/Button'
import { Colors } from '@/constants/colors'

// ---------------------------------------------------------------------------
// TermsCheckbox
// ---------------------------------------------------------------------------
interface TermsCheckboxProps {
  checked: boolean
  onToggle: () => void
  error?: string
}

function TermsCheckbox({ checked, onToggle, error }: TermsCheckboxProps) {
  return (
    <View style={cbStyles.wrapper}>
      <TouchableOpacity
        style={cbStyles.row}
        onPress={onToggle}
        activeOpacity={0.75}
        accessibilityRole="checkbox"
        accessibilityState={{ checked }}
      >
        <View style={[cbStyles.box, checked && cbStyles.boxChecked]}>
          {checked ? <Check size={13} color={Colors.text.inverse} strokeWidth={2.5} /> : null}
        </View>
        <Text style={cbStyles.text}>
          I agree to{' '}
          <Text style={cbStyles.link}>Terms &amp; Conditions</Text>
        </Text>
      </TouchableOpacity>
      {error != null ? <Text style={cbStyles.error}>{error}</Text> : null}
    </View>
  )
}

const cbStyles = StyleSheet.create({
  wrapper: {
    marginBottom: 20,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  box: {
    width: 22,
    height: 22,
    borderRadius: 6,
    borderWidth: 1.5,
    borderColor: Colors.border.strong,
    backgroundColor: Colors.bg.surface,
    alignItems: 'center',
    justifyContent: 'center',
  },
  boxChecked: {
    backgroundColor: Colors.teal[500],
    borderColor: Colors.teal[500],
  },
  text: {
    fontSize: 14,
    color: Colors.text.secondary,
    flexShrink: 1,
  },
  link: {
    color: Colors.teal[400],
    fontWeight: '600',
  },
  error: {
    marginTop: 4,
    fontSize: 12,
    color: Colors.danger,
    marginLeft: 32,
  },
})

// ---------------------------------------------------------------------------
// RegisterScreen
// ---------------------------------------------------------------------------
export default function RegisterScreen() {
  const router = useRouter()
  const insets = useSafeAreaInsets()
  const setAuth = useAuthStore((s) => s.setAuth)
  const [serverError, setServerError] = useState<string | null>(null)
  const [termsAccepted, setTermsAccepted] = useState(false)
  const [termsError, setTermsError] = useState<string | undefined>()

  const {
    control,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<RegisterFormValues>({
    resolver: zodResolver(registerSchema),
    defaultValues: { userName: '', email: '', password: '', confirmPassword: '' },
  })

  const password = watch('password')

  const onSubmit = async (values: RegisterFormValues) => {
    if (!termsAccepted) {
      setTermsError('You must accept the Terms & Conditions.')
      return
    }
    setTermsError(undefined)
    setServerError(null)
    try {
      const data = await authApi.register({
        email: values.email,
        password: values.password,
        userName: values.userName,
      })
      await setAuth(
        { id: data.userId!, email: data.email! },
        data.accessToken!,
        data.refreshToken!,
      )
      router.replace('/(app)')
    } catch {
      setServerError('Registration failed. The email or username may already be taken.')
    }
  }

  return (
    <View style={styles.root}>
      <StatusBar barStyle="light-content" />

      {/* Background gradient */}
      <LinearGradient
        colors={['#0A1F0E', '#061209', '#030A05']}
        style={StyleSheet.absoluteFill}
      />

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView
          contentContainerStyle={[
            styles.scroll,
            { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 32 },
          ]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Back button */}
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => router.back()}
            activeOpacity={0.75}
            accessibilityLabel="Go back"
            accessibilityRole="button"
          >
            <ArrowLeft size={20} color={Colors.text.primary} strokeWidth={2} />
          </TouchableOpacity>

          {/* Heading */}
          <View style={styles.headingRow}>
            <Text style={styles.titleWhite}>Join </Text>
            <Text style={styles.titleAccent}>Us</Text>
          </View>
          <Text style={styles.subtitle}>
            Start tracking your expenses automatically today.
          </Text>

          {/* Server error */}
          {serverError != null ? (
            <View style={styles.errorBox}>
              <Text style={styles.errorBoxText}>{serverError}</Text>
            </View>
          ) : null}

          {/* Form */}
          <View style={styles.form}>
            <Controller
              control={control}
              name="userName"
              render={({ field: { value, onChange } }) => (
                <AppTextInput
                  label="Full Name"
                  value={value}
                  onChangeText={onChange}
                  error={errors.userName?.message}
                  autoCapitalize="words"
                  placeholder="Your name"
                  autoComplete="name"
                />
              )}
            />

            <Controller
              control={control}
              name="email"
              render={({ field: { value, onChange } }) => (
                <AppTextInput
                  label="Email"
                  value={value}
                  onChangeText={onChange}
                  error={errors.email?.message}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  placeholder="you@example.com"
                  autoComplete="email"
                />
              )}
            />

            <Controller
              control={control}
              name="password"
              render={({ field: { value, onChange } }) => (
                <PasswordInput
                  label="Create Password"
                  value={value}
                  onChangeText={onChange}
                  error={errors.password?.message}
                  placeholder="Min. 8 characters"
                  autoComplete="new-password"
                />
              )}
            />

            <PasswordStrengthIndicator password={password} />

            <Controller
              control={control}
              name="confirmPassword"
              render={({ field: { value, onChange } }) => (
                <PasswordInput
                  label="Confirm Password"
                  value={value}
                  onChangeText={onChange}
                  error={errors.confirmPassword?.message}
                  placeholder="Repeat your password"
                  autoComplete="new-password"
                />
              )}
            />

            <TermsCheckbox
              checked={termsAccepted}
              onToggle={() => {
                setTermsAccepted((v) => !v)
                setTermsError(undefined)
              }}
              error={termsError}
            />
          </View>

          {/* Submit */}
          <Button
            label="Create Account"
            variant="mint"
            loading={isSubmitting}
            onPress={handleSubmit(onSubmit)}
            style={styles.submitButton}
          />

          {/* Footer */}
          <View style={styles.footer}>
            <Text style={styles.footerText}>Already have an account? </Text>
            <TouchableOpacity
              onPress={() => router.push('/(auth)/login')}
              activeOpacity={0.7}
            >
              <Text style={styles.footerLink}>Log In</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  )
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#030A05',
  },
  flex: {
    flex: 1,
  },
  scroll: {
    flexGrow: 1,
    paddingHorizontal: 24,
  },

  // Back button
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.default,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 28,
  },

  // Heading
  headingRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    marginBottom: 10,
  },
  titleWhite: {
    fontSize: 38,
    fontWeight: '800',
    color: Colors.text.primary,
    letterSpacing: -0.5,
  },
  titleAccent: {
    fontSize: 38,
    fontWeight: '800',
    color: '#F9A8D4',
    letterSpacing: -0.5,
  },
  subtitle: {
    fontSize: 15,
    color: Colors.text.secondary,
    marginBottom: 32,
    lineHeight: 22,
  },

  // Error
  errorBox: {
    backgroundColor: 'rgba(239,68,68,0.12)',
    borderWidth: 1,
    borderColor: Colors.danger,
    borderRadius: 12,
    padding: 12,
    marginBottom: 16,
  },
  errorBoxText: {
    color: Colors.danger,
    fontSize: 13,
    lineHeight: 18,
  },

  form: {
    width: '100%',
  },

  submitButton: {
    width: '100%',
    marginBottom: 28,
  },

  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  footerText: {
    fontSize: 14,
    color: Colors.text.secondary,
  },
  footerLink: {
    fontSize: 14,
    color: Colors.teal[400],
    fontWeight: '600',
  },
})
