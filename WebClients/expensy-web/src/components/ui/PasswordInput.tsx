import React, { useState } from 'react'
import { TouchableOpacity } from 'react-native'
import { Eye, EyeOff } from 'lucide-react-native'
import { AppTextInput } from './AppTextInput'
import { Colors } from '@/constants/colors'

interface PasswordInputProps {
  label: string
  value: string
  onChangeText: (text: string) => void
  error?: string
  placeholder?: string
  autoComplete?: 'current-password' | 'new-password' | 'password'
  leftIcon?: React.ReactNode
}

export function PasswordInput({
  label,
  value,
  onChangeText,
  error,
  placeholder,
  autoComplete = 'current-password',
  leftIcon,
}: PasswordInputProps) {
  const [visible, setVisible] = useState(false)

  const EyeIcon = visible ? EyeOff : Eye

  return (
    <AppTextInput
      label={label}
      value={value}
      onChangeText={onChangeText}
      error={error}
      placeholder={placeholder}
      autoCapitalize="none"
      autoComplete={autoComplete}
      secureTextEntry={!visible}
      leftIcon={leftIcon}
      rightElement={
        <TouchableOpacity
          onPress={() => setVisible((v) => !v)}
          hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          accessibilityLabel={visible ? 'Hide password' : 'Show password'}
          accessibilityRole="button"
        >
          <EyeIcon size={20} color={Colors.text.muted} strokeWidth={1.8} />
        </TouchableOpacity>
      }
    />
  )
}
