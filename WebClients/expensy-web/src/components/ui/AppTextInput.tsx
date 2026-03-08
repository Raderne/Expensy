import React, { ReactNode, useState } from 'react'
import {
  KeyboardTypeOptions,
  StyleSheet,
  Text,
  TextInput,
  TextInputProps,
  View,
} from 'react-native'
import { Colors } from '@/constants/colors'

interface AppTextInputProps {
  label: string
  value: string
  onChangeText: (text: string) => void
  error?: string
  secureTextEntry?: boolean
  keyboardType?: KeyboardTypeOptions
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters'
  placeholder?: string
  autoComplete?: TextInputProps['autoComplete']
  leftIcon?: ReactNode
  rightElement?: ReactNode
}

export function AppTextInput({
  label,
  value,
  onChangeText,
  error,
  secureTextEntry = false,
  keyboardType = 'default',
  autoCapitalize = 'sentences',
  placeholder,
  autoComplete,
  leftIcon,
  rightElement,
}: AppTextInputProps) {
  const [isFocused, setIsFocused] = useState(false)

  const borderColor = error
    ? Colors.danger
    : isFocused
    ? Colors.purple[500]
    : Colors.border.default

  return (
    <View style={styles.wrapper}>
      <Text style={styles.label}>{label}</Text>
      <View style={[styles.inputRow, { borderColor }]}>
        {leftIcon != null ? (
          <View style={styles.leftIconContainer}>{leftIcon}</View>
        ) : null}
        <TextInput
          style={[
            styles.input,
            leftIcon != null && styles.inputWithLeftIcon,
            rightElement != null && styles.inputWithRightElement,
          ]}
          value={value}
          onChangeText={onChangeText}
          secureTextEntry={secureTextEntry}
          keyboardType={keyboardType}
          autoCapitalize={autoCapitalize}
          placeholder={placeholder}
          placeholderTextColor={Colors.text.muted}
          autoComplete={autoComplete}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
        />
        {rightElement != null ? (
          <View style={styles.rightElementContainer}>{rightElement}</View>
        ) : null}
      </View>
      {error != null ? <Text style={styles.errorText}>{error}</Text> : null}
    </View>
  )
}

const styles = StyleSheet.create({
  wrapper: {
    marginBottom: 16,
  },
  label: {
    fontSize: 12,
    fontWeight: '500',
    color: Colors.text.secondary,
    marginBottom: 8,
    letterSpacing: 0.3,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.bg.surface,
    borderWidth: 1.5,
    borderRadius: 14,
    minHeight: 52,
  },
  leftIconContainer: {
    paddingLeft: 14,
    paddingRight: 4,
  },
  rightElementContainer: {
    paddingRight: 14,
    paddingLeft: 4,
  },
  input: {
    flex: 1,
    paddingHorizontal: 14,
    paddingVertical: 14,
    fontSize: 15,
    color: Colors.text.primary,
  },
  inputWithLeftIcon: {
    paddingLeft: 4,
  },
  inputWithRightElement: {
    paddingRight: 4,
  },
  errorText: {
    marginTop: 5,
    fontSize: 12,
    color: Colors.danger,
  },
})
