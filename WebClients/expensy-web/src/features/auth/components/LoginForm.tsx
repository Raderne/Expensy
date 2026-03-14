import React, { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Link, useRouter } from 'expo-router';

import { loginSchema, LoginFormValues } from '@/features/auth/schemas/auth.schema';
import { authClient } from '@/api/clients';
import { useAuthStore } from '@/store/auth.store';
import { AppTextInput } from '@/components/ui/AppTextInput';
import { Button } from '@/components/ui/Button';
import { Colors } from '@/constants/colors';

export function LoginForm() {
  const router = useRouter();
  const setAuth = useAuthStore((s) => s.setAuth);
  const [serverError, setServerError] = useState<string | null>(null);

  const {
    control,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  const onSubmit = async (values: LoginFormValues) => {
    setServerError(null);
    try {
      console.log('sending login');
      const data = await authClient.login({ email: values.email, password: values.password });
      console.log(data);
      // Generated AuthResponse fields are typed as optional — non-null assertions are safe
      // here because a successful 200 response always includes all token fields.
      await setAuth({ id: data.userId!, email: data.email! }, data.accessToken!, data.refreshToken!);
      router.replace('/(app)');
    } catch {
      setServerError('Invalid email or password. Please try again.');
    }
  };

  return (
    <View style={styles.container}>
      {serverError ? (
        <View style={styles.errorBox}>
          <Text style={styles.errorBoxText}>{serverError}</Text>
        </View>
      ) : null}

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
          />
        )}
      />

      <Controller
        control={control}
        name='password'
        render={({ field: { value, onChange } }) => (
          <AppTextInput
            label='Password'
            value={value}
            onChangeText={onChange}
            error={errors.password?.message}
            secureTextEntry
            autoCapitalize='none'
            placeholder='Your password'
            autoComplete='current-password'
          />
        )}
      />

      <Button label='Sign In' loading={isSubmitting} onPress={handleSubmit(onSubmit)} style={styles.submitButton} />

      <View style={styles.footer}>
        <Text style={styles.footerText}>Don't have an account? </Text>
        <Link href='/(auth)/register' style={styles.link}>
          Sign up
        </Link>
      </View>
    </View>
  );
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
});
