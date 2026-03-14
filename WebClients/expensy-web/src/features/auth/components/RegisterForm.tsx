import React, { useState } from 'react'
import { StyleSheet, Text, View } from 'react-native'
import { Controller, useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Link, useRouter } from 'expo-router'

import { registerSchema, RegisterFormValues } from '@/features/auth/schemas/auth.schema'
import { nswagAxios, BASE_URL } from '@/api/client'
import type { AuthResponse, RegisterRequest } from '@/api/types'
import { useAuthStore } from '@/store/auth.store'
import { AppTextInput } from '@/components/ui/AppTextInput'
import { Button } from '@/components/ui/Button'
import { PasswordStrengthIndicator } from './PasswordStrengthIndicator'
import { Colors } from '@/constants/colors'

export function RegisterForm() {
  const router = useRouter()
  const setAuth = useAuthStore((s) => s.setAuth)
  const [serverError, setServerError] = useState<string | null>(null)

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
    setServerError(null)
    try {
      // Register returns AuthResponse directly — use it to log the user in without a
      // separate login round-trip. The generated AuthClient does not expose a register
      // endpoint, so we call the API directly via nswagAxios (raw-string transform
      // applied) and parse the response ourselves.
      const req: RegisterRequest = {
        email: values.email,
        password: values.password,
        userName: values.userName,
      }
      const { data: rawData } = await nswagAxios.post<string>(
        `${BASE_URL}/api/Auth/register`,
        req,
      )
      const data: AuthResponse = typeof rawData === 'string' ? JSON.parse(rawData) : rawData
      // Generated AuthResponse fields are typed as optional — non-null assertions are safe
      // here because a successful 201 response always includes all token fields.
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
    <View style={styles.container}>
      {serverError ? (
        <View style={styles.errorBox}>
          <Text style={styles.errorBoxText}>{serverError}</Text>
        </View>
      ) : null}

      <Controller
        control={control}
        name="userName"
        render={({ field: { value, onChange } }) => (
          <AppTextInput
            label="Username"
            value={value}
            onChangeText={onChange}
            error={errors.userName?.message}
            autoCapitalize="none"
            placeholder="yourname"
            autoComplete="username"
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
          <AppTextInput
            label="Password"
            value={value}
            onChangeText={onChange}
            error={errors.password?.message}
            secureTextEntry
            autoCapitalize="none"
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
          <AppTextInput
            label="Confirm Password"
            value={value}
            onChangeText={onChange}
            error={errors.confirmPassword?.message}
            secureTextEntry
            autoCapitalize="none"
            placeholder="Repeat your password"
            autoComplete="new-password"
          />
        )}
      />

      <Button
        label="Create Account"
        loading={isSubmitting}
        onPress={handleSubmit(onSubmit)}
        style={styles.submitButton}
      />

      <View style={styles.footer}>
        <Text style={styles.footerText}>Already have an account? </Text>
        <Link href="/(auth)/login" style={styles.link}>
          Sign in
        </Link>
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  errorBox: {
    backgroundColor: 'rgba(239,68,68,0.12)',
    borderWidth: 1,
    borderColor: Colors.danger,
    borderRadius: 10,
    padding: 12,
    marginBottom: 16,
  },
  errorBoxText: {
    color: Colors.danger,
    fontSize: 13,
    lineHeight: 18,
  },
  submitButton: {
    marginTop: 4,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 20,
  },
  footerText: {
    fontSize: 14,
    color: Colors.text.secondary,
  },
  link: {
    fontSize: 14,
    color: Colors.purple[500],
    fontWeight: '600',
  },
})
