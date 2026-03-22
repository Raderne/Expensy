import React, { useCallback, useEffect, useState } from 'react';
import { KeyboardAvoidingView, Platform, ScrollView, StatusBar, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Mail, Lock, Wallet, FingerprintPattern } from 'lucide-react-native';
import * as LocalAuthentication from 'expo-local-authentication';

import { loginSchema, LoginFormValues } from '@/features/auth/schemas/auth.schema';
import { useAuthStore } from '@/store/auth.store';
import { getBiometricEnabled, getBiometricSession, saveBiometricSession } from '@/utils/biometricPreference';
import { AppTextInput } from '@/components/ui/AppTextInput';
import { PasswordInput } from '@/components/ui/PasswordInput';
import { Button } from '@/components/ui/Button';
import { Colors } from '@/constants/colors';
import { authClient } from '@/api/clients';

export default function LoginScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const setAuth = useAuthStore((s) => s.setAuth);
  const [serverError, setServerError] = useState<string | null>(null);
  const [biometricAvailable, setBiometricAvailable] = useState(false);
  const [biometricLoading, setBiometricLoading] = useState(false);

  const {
    control,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  // Check biometric availability on mount
  useEffect(() => {
    const checkBiometrics = async () => {
      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      if (!hasHardware) return;

      const isEnrolled = await LocalAuthentication.isEnrolledAsync();
      if (!isEnrolled) return;

      const isEnabled = await getBiometricEnabled();
      if (!isEnabled) return;

      // Only show button if a biometric session exists (survives logout)
      const session = await getBiometricSession();
      if (session) {
        setBiometricAvailable(true);
      }
    };

    checkBiometrics();
  }, []);

  const onSubmit = async (values: LoginFormValues) => {
    setServerError(null);
    try {
      console.log('login start');
      const data = await authClient.login({ email: values.email, password: values.password });
      console.log('login resp', data);
      await setAuth({ id: data.userId!, email: data.email! }, data.accessToken!, data.refreshToken!);
      router.replace('/(app)');
    } catch {
      setServerError('Invalid email or password. Please try again.');
    }
  };

  const onBiometricPress = useCallback(async () => {
    setServerError(null);
    setBiometricLoading(true);

    try {
      const session = await getBiometricSession();
      if (!session) {
        setServerError('No saved session. Please log in with email first.');
        setBiometricAvailable(false);
        return;
      }

      const result = await LocalAuthentication.authenticateAsync({
        promptMessage: 'Authenticate to continue',
        fallbackLabel: 'Use passcode',
        cancelLabel: 'Cancel',
      });

      if (!result.success) return;

      const data = await authClient.refresh({ userId: session.userId, refreshToken: session.refreshToken });
      // Update biometric session with rotated token so next login works too
      await saveBiometricSession(data.userId!, data.refreshToken!);
      await setAuth(
        { id: data.userId!, email: data.email! },
        data.accessToken!,
        data.refreshToken!,
      );
      router.replace('/(app)');
    } catch {
      setServerError('Biometric authentication failed. Please log in with email.');
    } finally {
      setBiometricLoading(false);
    }
  }, [setAuth, router]);

  return (
    <View style={styles.root}>
      <StatusBar barStyle='light-content' />

      {/* Background gradient */}
      <LinearGradient colors={['#1A0A2E', '#0D0718', '#0A0A0F']} style={StyleSheet.absoluteFill} />

      <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <ScrollView
          contentContainerStyle={[styles.scroll, { paddingTop: insets.top + 32, paddingBottom: insets.bottom + 32 }]}
          keyboardShouldPersistTaps='handled'
          showsVerticalScrollIndicator={false}
        >
          {/* Logo area */}
          <View style={styles.logoArea}>
            <View style={styles.logoSquare}>
              <Wallet size={36} color={Colors.teal[400]} strokeWidth={1.8} />
              {/* Badge */}
              <View style={styles.logoBadge}>
                <Text style={styles.logoBadgeText}>+</Text>
              </View>
            </View>
          </View>

          {/* Heading */}
          <Text style={styles.title}>Welcome Back</Text>
          <Text style={styles.subtitle}>Track your wealth, effortlessly.</Text>

          {/* Server error */}
          {serverError != null ? (
            <View style={styles.errorBox}>
              <Text style={styles.errorBoxText}>{serverError}</Text>
            </View>
          ) : null}

          {/* Fields */}
          <View style={styles.form}>
            <Controller
              control={control}
              name='email'
              render={({ field: { value, onChange } }) => (
                <AppTextInput
                  label='Email'
                  value={value}
                  onChangeText={onChange}
                  error={errors.email?.message}
                  keyboardType='email-address'
                  autoCapitalize='none'
                  placeholder='you@example.com'
                  autoComplete='email'
                  leftIcon={<Mail size={18} color={Colors.text.muted} strokeWidth={1.8} />}
                />
              )}
            />

            <Controller
              control={control}
              name='password'
              render={({ field: { value, onChange } }) => (
                <PasswordInput
                  label='Password'
                  value={value}
                  onChangeText={onChange}
                  error={errors.password?.message}
                  placeholder='Your password'
                  autoComplete='current-password'
                  leftIcon={<Lock size={18} color={Colors.text.muted} strokeWidth={1.8} />}
                />
              )}
            />

            {/* Forgot password */}
            <TouchableOpacity style={styles.forgotRow} activeOpacity={0.7}>
              <Text style={styles.forgotText}>Forgot Password?</Text>
            </TouchableOpacity>
          </View>

          {/* Login button */}
          <Button label='Login  →' variant='primary' loading={isSubmitting} onPress={handleSubmit(onSubmit)} style={styles.loginButton} />

          {/* Biometric section — only rendered when hardware + enrollment + stored session are all present */}
          {biometricAvailable ? (
            <>
              <View style={styles.dividerRow}>
                <View style={styles.dividerLine} />
                <Text style={styles.dividerText}>OR CONTINUE WITH</Text>
                <View style={styles.dividerLine} />
              </View>

              <TouchableOpacity
                style={[styles.biometricButton, biometricLoading && styles.biometricButtonDisabled]}
                activeOpacity={0.75}
                onPress={onBiometricPress}
                disabled={biometricLoading}
                accessibilityRole='button'
                accessibilityLabel='Use biometrics to log in'
              >
                <FingerprintPattern size={22} color={Colors.purple[400]} strokeWidth={1.6} />
                <Text style={styles.biometricLabel}>
                  {biometricLoading ? 'Authenticating...' : 'Use Biometrics'}
                </Text>
              </TouchableOpacity>
            </>
          ) : null}

          {/* Footer */}
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Colors.bg.base,
  },
  flex: {
    flex: 1,
  },
  scroll: {
    flexGrow: 1,
    paddingHorizontal: 24,
    alignItems: 'center',
  },

  // Logo
  logoArea: {
    marginBottom: 28,
  },
  logoSquare: {
    width: 80,
    height: 80,
    borderRadius: 22,
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.default,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoBadge: {
    position: 'absolute',
    bottom: -6,
    right: -6,
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: Colors.purple[500],
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: Colors.bg.base,
  },
  logoBadgeText: {
    color: Colors.text.primary,
    fontSize: 13,
    fontWeight: '700',
    lineHeight: 16,
  },

  // Heading
  title: {
    fontSize: 32,
    fontWeight: '700',
    color: Colors.text.primary,
    letterSpacing: -0.5,
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 15,
    color: Colors.text.secondary,
    textAlign: 'center',
    marginBottom: 36,
  },

  // Error
  errorBox: {
    width: '100%',
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

  // Form
  form: {
    width: '100%',
  },
  forgotRow: {
    alignItems: 'flex-end',
    marginTop: -6,
    marginBottom: 8,
  },
  forgotText: {
    fontSize: 13,
    color: Colors.text.primary,
    fontWeight: '500',
  },

  // Login button
  loginButton: {
    width: '100%',
    marginTop: 8,
    marginBottom: 28,
  },

  // Divider
  dividerRow: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 20,
    gap: 10,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: Colors.border.default,
  },
  dividerText: {
    fontSize: 11,
    color: Colors.text.muted,
    fontWeight: '600',
    letterSpacing: 0.8,
  },

  // Biometric
  biometricButton: {
    width: '100%',
    height: 52,
    borderRadius: 14,
    backgroundColor: Colors.bg.elevated,
    borderWidth: 1,
    borderColor: Colors.border.default,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    marginBottom: 32,
  },
  biometricButtonDisabled: {
    opacity: 0.5,
  },
  biometricLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.text.primary,
  },

  // Footer
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  footerText: {
    fontSize: 14,
    color: Colors.text.secondary,
  },
  footerLink: {
    fontSize: 14,
    color: Colors.purple[500],
    fontWeight: '600',
  },
});
